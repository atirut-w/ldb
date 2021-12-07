# LDB
Make Lua debugging easier.

# Installation
## OpenOS
Copy `ldb.lua` to `/usr/bin/`. Alternatively, if you have Bake installed, you can run `bake install` to install it.

## Real operating systems
This works on any operating system that supports Lua(haven't tested this on Windows). Just install it like how you would any other script-based program(hint: shebangs and `chmod`).

# Usage
Run `ldb [program]` where `[program]` is the Lua script you want to debug.

# Debugging commands
To get a list of commands, use the `help` command.
