import necsus, ../sdl2util

type
    Position* = object
        x*, y*: float

    Velocity* = object
        x*, y*: float

proc move*(
    dt: TimeDelta,
    particles: Query[tuple[position: ptr Position, velocity: Velocity]],
    screenSize: Shared[ScreenSize]
) =
    for (eid, comp) in particles:

        comp.position.x = comp.position.x + (comp.velocity.x * dt)
        comp.position.y = comp.position.y + (comp.velocity.y * dt)

        if comp.position.x < -20:
            comp.position.x = screenSize.get().width.float + 20
        elif comp.position.x > screenSize.get().width.float + 20:
            comp.position.x = -20.0

        if comp.position.y < -20:
            comp.position.y = screenSize.get().height.float + 20
        elif comp.position.y > screenSize.get().height.float + 20:
            comp.position.y = -20.0
