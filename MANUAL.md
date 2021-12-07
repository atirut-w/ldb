# LDB debugger user manual.
A handbook for debugging your codes using LDB.

## Introduction
LDB is a debugger for Lua. Although simple, it is very useful when you have to set breakpoints to inspect variables, or when you just don't know why that one line of code is crashing your program.

To launch LDB, run `lua ldb.lua`. Alternatively, if you made LDB executable(shebang and `chmod`), you can run it with `./ldb.lua` or just `ldb.lua` if you added to your path(`~/.local/bin`, `/usr/bin`, etc.). It is recommended that you change the file name to `ldb` if you want to use it as a command.

After you launched LDB, you will get a prompt. You can type `help` to see the list of commands.

```
$ lua ldb.lua 
LDB Lua debugger
Type "help" for help
(ldb) 
```

Tip: You can supply a lua script as an argument to LDB. For example, `lua ldb.lua myscript.lua`.

## Loading a script
Before you can start debugging, you need to load a script. You can do this by using the `load` command(use `help load` to see the usage).

```
(ldb) load test.lua
Program loaded
```

`test.lua`'s content:

```lua
local str1 = "Hello, "
local str2 = "World!"
print(str1 .. str2)
```

## Running a script
After loading the script, you can run it by simply using the `run` command. You can give arguments to the script by putting  them after the `run` command, i.e. `run arg1 arg2`.

```
(ldb) run
Hello, World!
Program finished
```

## Debugging it
As an example, let's set a breakpoint right on line 1 by using the `bp` command. This command toggles the breakpoint on the line you specify.

```
(ldb) bp 1
```

You can see all breakpoints by typing running the `list_bp` command.

```
(ldb) list_bp
1: enabled
```

Now when you run the program using the `run` command, it will stop at the breakpoint.

```
(ldb) run
Breakpoint reached at line 1
```

You can continue the execution using the `continue` command, or check out the stack trace by running `trace`.

```
(ldb) trace
Trace:
        [C]: in function 'coroutine.yield'
        [string "test.lua"]:1: in main chunk
```

When you continue the execution, the program will keep executing until it reaches the next breakpoint, exit, or crashes for some other reason.

```
(ldb) continue
Hello, World!
Program finished
```

## Breakpoint statements
Breakpoints are useful, but statements can take your debugging to the next level.

When you supply more arguments to the `bp` command, they will be used as breakpoint statements. These can be anything from literals to expressions, and are separated by commas. Note that when you supply the statements, `bp` will enable breakpoints instead of toggling them.

```
(ldb) bp 1 "This is a breakpoint"
(ldb) run
Breakpoint reached at line 1
Breakpoint value: This is a breakpoint
```

You can also reference variables in the statements. Please note that when breakpoints are hit, the line they're on will be execxuted *after* you continue the execution.

This means that, for example, if you want to see the variable `str1`, you will have to set your breakpoint on the line just after the assignment.

```
(ldb) bp 2 str1
(ldb) run
Breakpoint reached at line 2
Breakpoint value: Hello, 
```

Multiple statements example:

```
(ldb) bp 3 str1, str2
(ldb) run
Breakpoint reached at line 3
Breakpoint value: {"Hello, ", "World!"}
```

After you're done debugging, you can continue the program's execution until it's done, or you can use the `stop` command to stop the execution.
