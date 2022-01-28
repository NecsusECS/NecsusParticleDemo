import sdl2, necsus

proc exitGame*(exit: var Shared[NecsusRun]) =
    ## Looks for exit events and escape key presses, then quits
    var event = defaultEvent
    while pollEvent(event):
        case event.kind
        of QuitEvent:
            exit.set(ExitLoop)
        of KeyUp:
            if event.key.keysym.scancode == SDL_SCANCODE_ESCAPE:
                exit.set(ExitLoop)
        else:
            discard
