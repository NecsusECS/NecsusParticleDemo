import necsus, sdl2util, sdl2, systems/[exit, particles, render, movement]

proc demoApp(screenSize: ScreenSize, renderer: RendererPtr) {.necsus(
    [],
    [~createParticles, ~exitGame, ~move, ~renderer],
    [],
    newNecsusConf()
).}

let screenSize = (width: 640, height: 480)

initialize(screenSize, window, renderer):
    demoApp(screenSize, renderer)
