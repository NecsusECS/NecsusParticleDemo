import necsus, sdl2util, sdl2, random, math, sdl2/gfx, vmath

type
    Position* {.byref.} = object
        position: Vec2

    Velocity* {.byref.} = object
        velocity: Vec2

    Mass* = float32

    Visuals* {.byref.} = object
        r*, g*, b*: uint8
        radius*: int16

const maxInitialVel = 3.0
const maxInitialRotation = 50.0'f32
const centralMass = 1200.0'f32
const maxMass = 2.0'f32

proc middle(screen: Shared[ScreenSize]): auto =
     vec2(screen.getOrRaise.width / 2, screen.getOrRaise.height / 2)

proc createCentralMass(screenSize: Shared[ScreenSize], spawn: Spawn[(Mass, Position)]) {.startupSys.} =
    ## Create a central body right in the middle of the screen
    spawn.with(centralMass, Position(position: screenSize.middle))

proc createBodies*(
    screenSize: Shared[ScreenSize],
    spawn: Spawn[(Mass, Position, Velocity, Visuals)],
    count: Query[(Velocity, )]
) =
    ## Creates an initial set of zooming particles
    let centralPos = screenSize.middle
    for i in count.len..100:
        let mass = rand(0.5'f32..maxMass)

        let pos = vec2(rand(0..screenSize.getOrRaise.width).float, rand(0..screenSize.getOrRaise.height).float)

        # Create a velocity that points at the central mass, then randomly rotate it
        let baseVelocity = (centralPos - pos).normalize * rand(0.1..maxInitialVel)
        let velocity = rotate(rand(-maxInitialRotation..maxInitialRotation)) * baseVelocity

        spawn.with(
            mass,
            Position(position: pos),
            Velocity(velocity: velocity),
            Visuals(radius: int16(10 * (mass / maxMass)) + 1)
        )

proc simulate(
    movingBodies: FullQuery[(ptr Position, ptr Velocity, Mass)],
    allBodies: FullQuery[(Position, Mass)]
) =
    ## Adjusts the velocity for every body
    for eid, (pos, vel, mass) in movingBodies:
        var accum = vec2(0.0, 0.0)
        for otherEid, (otherPos, otherMass) in allBodies:
            if otherEid != eid:
                let diff = otherPos.position - pos.position

                # Reduce acceleration in close encounters
                let distance = max(dot(diff, diff), 10_000'f32)

                let distanceSqrt = distance.sqrt
                let force = otherMass / distance

                accum += diff * (force / distanceSqrt)

        vel.velocity += accum / mass

proc move(dt: TimeDelta, bodies: Query[(ptr Position, Velocity)]) =
    ## Moves all the bodies based on their velocity
    for (pos, vel) in bodies:
        pos.position += vel.velocity * dt() * 100

proc cleanup(bodies: FullQuery[(ptr Position, )], screenSize: Shared[ScreenSize], delete: Delete) =
    ## Destroys any bodies that get too far off screen
    let middle = screenSize.middle
    for eid, (pos, ) in bodies:
        if (pos.position - middle).lengthSq > 1_000_000:
            delete(eid)

proc visuals*(bodies: Query[(Velocity, Position, ptr Visuals)], screenSize: Shared[ScreenSize]) =
    ## Adjust the color of each body based on its velocity
    let center = screenSize.middle
    let boundary = center.lengthSq

    for (vel, pos, visuals) in bodies:
        visuals.r = max(180 - vel.velocity.lengthSq / 3 * 255, 100).uint8
        visuals.b = max(255 - (center - pos.position).lengthSq / boundary * 400, 0).uint8
        visuals.g = 0

proc renderer*(renderer: Shared[RendererPtr], bodies: Query[(Position, Visuals)]) =
    renderer.getOrRaise.setDrawColor(0, 0, 0, 255)
    renderer.getOrRaise.clear()
    renderer.getOrRaise.setDrawBlendMode(BlendMode_Blend)

    for (pos, visuals) in bodies:
        renderer.getOrRaise.filledCircleRGBA(
            pos.position.x.int16, pos.position.y.int16, visuals.radius,
            visuals.r, visuals.g, visuals.b, 255
        )

    renderer.getOrRaise.present()

proc demoApp(screenSize: ScreenSize, renderer: RendererPtr) {.necsus(
    [ ~createCentralMass, ~exitGame, ~createBodies, ~simulate, ~move, ~cleanup, ~visuals, ~renderer, ~enforceFrameRate ],
    newNecsusConf(entitySize = 10_000, componentSize = 10_000)
).}

let screenSize = (width: 1024, height: 768)

initialize(screenSize, window, renderer):
    demoApp(screenSize, renderer)
