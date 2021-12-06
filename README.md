# LDB
A simple Lua debugger written in Lua. Currently only tested on OpenComputer's OpenOS.

# Installation
## OpenOS
Copy `ldb.lua` to `/usr/bin/`. Alternatively, if you have Bake installed, you can run `bake install` to install it.

## Real operating systems
This works on any operating system that supports Lua(haven't tested this on Windows). Just install it like how you would any other script-based program(hint: shebangs and `chmod`).

# Usage
Run `ldb [program]` where `[program]` is the Lua script you want to debug.

# Debugging commands
- `load` - Loads a Lua script into the debugger. This is done automatically if you run `ldb [program]`.
- `run` - Runs the loaded script.
- `continue` - Continues running the script(after hitting a breakpoint).
- `stop` - Stops the script.
- `trace` - Prints the stack trace.
- `source [line]` - Prints the source code of loaded script or a specific line.
- `breakpoint <line>` - Toggle a breakpoint at a specific line.
- `breakpoints` - Prints all breakpoints.

