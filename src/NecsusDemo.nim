import necsus, sdl2util, sdl2, random, math, sdl2/gfx, vmath

type
    Position* = object
        position: Vec2

    Velocity* = object
        velocity: Vec2

    Mass* = object
        mass: float32

    Visuals* = object
        r*, g*, b*: uint8
        radius*: int16

const maxInitialVel = 3.0
const maxInitialRotation = 50.0'f32
const centralMass = 1200.0'f32
const maxMass = 2.0'f32
const maxSpeed = 10

proc middle(screen: Shared[ScreenSize]): auto =
     vec2(screen.get().width / 2, screen.get().height / 2)

proc createCentralMass(screenSize: Shared[ScreenSize], spawn: Spawn[(Position, Mass)]) =
    ## Create a central body right in the middle of the screen
    discard spawn.with(Position(position: screenSize.middle), Mass(mass: centralMass))

proc createBodies*(
    screenSize: Shared[ScreenSize],
    spawn: Spawn[(Position, Velocity, Mass, Visuals)],
    count: Query[(Velocity, )]
) =
    ## Creates an initial set of zooming particles
    let centralPos = screenSize.middle
    for i in count.len..100:
        let mass = rand(0.5'f32..maxMass)

        let pos = vec2(rand(0..screenSize.get().width).float, rand(0..screenSize.get().height).float)

        # Create a velocity that points at the central mass, then randomly rotate it
        let baseVelocity = (centralPos - pos).normalize * rand(0.1..maxInitialVel)
        let velocity = rotate(rand(-maxInitialRotation..maxInitialRotation)) * baseVelocity

        discard spawn.with(
            Position(position: pos),
            Velocity(velocity: velocity),
            Mass(mass: mass),
            Visuals(radius: int16(10 * (mass / maxMass)) + 1)
        )

proc simulate(
    dt: TimeElapsed,
    movingBodies: Query[(ptr Position, ptr Velocity, ptr Mass)],
    allBodies: Query[(ptr Position, ptr Mass)]
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
                let force = otherMass.mass / distance

                accum += diff * (force / distanceSqrt)

        vel.velocity += accum / mass.mass
            

proc move(dt: TimeElapsed, bodies: Query[(ptr Position, ptr Velocity)]) =
    ## Moves all the bodies based on their velocity
    for eid, (pos, vel) in bodies:
        pos.position += vel.velocity * dt

proc cleanup(bodies: Query[(ptr Position, )], screenSize: Shared[ScreenSize], delete: Delete) =
    ## Destroys any bodies that get too far off screen
    let middle = screenSize.middle
    for eid, (pos, ) in bodies:
        if (pos.position - middle).lengthSq > 1_000_000:
            delete(eid)

proc visuals*(bodies: Query[(ptr Velocity, ptr Position, ptr Visuals)], screenSize: Shared[ScreenSize]) =
    ## Adjust the color of each body based on its velocity
    let center = screenSize.middle
    let boundary = center.lengthSq

    for eid, (vel, pos, visuals) in bodies:
        visuals.r = max(180 - vel.velocity.lengthSq / 3 * 255, 100).uint8
        visuals.b = max(255 - (center - pos.position).lengthSq / boundary * 400, 0).uint8
        visuals.g = 0

proc renderer*(renderer: Shared[RendererPtr], bodies: Query[(Position, Visuals)]) =
    renderer.get().setDrawColor(0, 0, 0, 255)
    renderer.get().clear()
    renderer.get().setDrawBlendMode(BlendMode_Blend)

    for (pos, visuals) in bodies:
        renderer.get().filledCircleRGBA(
            pos.position.x.int16, pos.position.y.int16, visuals.radius,
            visuals.r, visuals.g, visuals.b, 255
        )

    renderer.get().present()

proc demoApp(screenSize: ScreenSize, renderer: RendererPtr) {.necsus(
    [~createCentralMass ],
    [~exitGame, ~createBodies, ~simulate, ~move, ~cleanup, ~visuals, ~renderer, ~enforceFrameRate],
    [],
    newNecsusConf(entitySize = 10_000, componentSize = 10_000)
).}

let screenSize = (width: 1024, height: 768)

initialize(screenSize, window, renderer):
    demoApp(screenSize, renderer)
