import sdl2, necsus, particles, movement

proc renderer*(
    renderer: Shared[RendererPtr],
    particles: Query[tuple[particle: Particle, position: Position]]
) =
    renderer.get().setDrawColor(0, 0, 0, 255)
    renderer.get().clear()
    renderer.get().setDrawBlendMode(BlendMode_Blend)

    for comp in particles:
        renderer.get().setDrawColor(comp.particle.r, comp.particle.g, comp.particle.b, comp.particle.a)
        var r = rect(comp.position.x.cint, comp.position.y.cint, 15, 15)
        renderer.get().fillRect(r)

    renderer.get().present()
