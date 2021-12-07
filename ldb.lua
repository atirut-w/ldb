local args = {...}

if ({["-h"] = true, ["--help"] = true})[args[1]] then
    print("Usage: ldb [program]")
    os.exit(true)
end

--- NOTE: I haveabsolutely no idea why I don't see people use this kind of lookup switch case in Lua.
---@param value any
---@param cases table<any, function>
local function switch(value, cases)
    return (cases[value] or (cases.default or function() end))()
end

---@param t table
local function dump(t)
    io.write("{")
    for i,v in ipairs(t) do
        switch(type(v), {
            string = function()
                io.write(("%q"):format(v))
            end,
            table = function()
                dump(v)
            end,
        })
        if i < #t then
            io.write(", ")
        end
    end
    print("}")
end

---@class DebugCommand
---@field description string
---@field args string
---@field handler function

---@type table<string, DebugCommand>
local commands = {}

local function register_command(name, description, args, handler)
    commands[name] = {
        description = description,
        args = args,
        handler = handler
    }
end

local function run_command(name, ...)
    if not commands[name] then
        print("Unknown command: " .. name)
        return
    end
    commands[name].handler(...)
end

register_command("help", "Prints this help message", "[command]", function(command)
    if command then
        if not commands[command] then
            print("Unknown command: " .. command)
            return
        end
        print(commands[command].description)
        print("Usage: " .. command .. " " .. commands[command].args)
    else
        print("Available commands:")
        for name, command in pairs(commands) do
            print("  " .. name .. " - " .. command.description)
        end
    end
end)

register_command("quit", "Quits the debugger", "", function()
    os.exit(true)
end)

-- Core debugging commands are registered here.
do
    ---@type string
    local program_name = nil
    ---@type table<integer, string>
    local program_source = {}
    ---@type thread
    local program_thread = nil
    ---@type table<integer, boolean>
    local breakpoints = {}
    ---@type string<integer, string>
    local bp_messages = {}

    register_command("load", "Loads a program", "<program>", function(path)
        if not path then
            print("Load what?")
            return
        end

        local file = io.open(path, "r")
        if not file then
            print("Program not found")
            return
        end

        program_name = path
        program_source = {}
        breakpoints = {}
        bp_messages = {}

        program_source = file:read("a")
        file:close()
        program_name = path
        print("Program loaded")
    end)

    register_command("bp", "Toogle breakpoint or set breakpoint message", "<line> [message]", function(line, ...)
        line = tonumber(line)
        if ... then
            breakpoints[line] = true
            bp_messages[line] = table.concat({...})
        else
            breakpoints[line] = not breakpoints[line]
        end
    end)

    register_command("list_bp", "List breakpoints", "", function()
        for line, enabled in pairs(breakpoints) do
            print(("%d: %s %s"):format(line, enabled and "enabled" or "disabled", bp_messages[line] or ""))
        end
    end)

    register_command("run", "Run the currently loaded program", "[args]", function(...)
        if not program_source then
            print("No program loaded")
        elseif program_thread then
            print("Program already running")
        end
        
        local lines = {}
        for line in program_source:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        for line, enabled in pairs(breakpoints) do
            if enabled then
                lines[line] = lines[line] .. ";coroutine.yield({line=" .. line .. ", message={" .. (bp_messages[line] or "") .. "}});"
            end
        end

        program_thread = coroutine.create(load(table.concat(lines, "\n"), program_name, "t", _G))
        run_command("continue", ...)
    end)

    register_command("stop", "Stop the currently running program", "", function()
        if not program_thread then
            print("No program running")
        else
            program_thread = nil
        end
    end)

    register_command("continue", "Continue the currently running program", "", function(...)
        -- The arguments for this command are only used internally send arguments to the program.
        -- Point: no need to document this command's arguments in the help.

        if not program_thread then
            print("No program running")
        else
            local success, result = coroutine.resume(program_thread, ...)

            if success then
                if coroutine.status(program_thread) == "dead" then
                    run_command("stop")
                    print(("Program finished. Return code %d"):format(result or 0))
                else
                    print("Breakpoint reached at line " .. result.line)
                    if #result.message > 0 then
                        io.write("Breakpoint value: ")
                        if #result.message == 1 then
                            if type(result.message[1]) == "table" then
                                dump(result.message[1])
                            else
                                print(result.message[1])
                            end
                        elseif #result.message > 1 then
                            dump(result.message)
                        end
                    end
                end
            else
                -- Even if `success` is false, it can be because the program used `os.exit()` with values.
                io.write("Program finished with possible error(s): ")
                dump({result})
                run_command("stop")
            end
        end
    end)
end

print([[LDB Lua debugger
Type "help" for help]])

if args[1] then
    run_command("load", args[1])
end

while true do
    io.write("(ldb) ")
    local input = io.read()

    local tokens = {}
    for token in input:gmatch("%S+") do
        table.insert(tokens, token)
    end

    if #tokens > 0 then
        run_command(table.remove(tokens, 1), table.unpack(tokens))
    end
end
