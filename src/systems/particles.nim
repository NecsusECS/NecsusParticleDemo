import necsus, random, movement, ../sdl2util

type
    Particle* = object
        r*, g*, b*, a*: uint8

const velocity_minmax = 200.0

proc createParticles*(
    total: var Local[int],
    screenSize: Shared[ScreenSize],
    spawn: Spawn[(Particle, Position, Velocity)]
) =
    ## Creates an initial set of zooming particles
    if total.get(0) < 5_000:
        for i in 1..100:
            total.set(total.get(0) + 1)
            let nonRed = rand(0..255).uint8
            discard spawn.with(
                Particle(r: rand(200..255).uint8, g: nonRed, b: nonRed, a: rand(100..255).uint8),
                Position(x: rand(-5..screenSize.get().width).float, y: rand(-5..screenSize.get().height).float),
                Velocity(x: rand(-velocity_minmax..velocity_minmax), y: rand(-velocity_minmax..velocity_minmax))
            )
