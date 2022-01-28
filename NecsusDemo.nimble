# Package

version       = "0.1.0"
author        = "Nycto"
description   = "A demo project for Necsus"
license       = "MIT"
srcDir        = "src"
bin           = @["NecsusDemo"]


# Dependencies

requires "nim >= 1.6.2", "sdl2", "necsus", "ringbuffer"
