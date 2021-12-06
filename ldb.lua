-- Lua debugger, written in Lua.

local args = {...}

if ({["-h"] = true, ["--help"] = true})[args[1]] then
    print("Usage: ldb [program] [arguments]")
    os.exit(0)
end

---@param value any
---@param cases table<any, function>
local function switch(value, cases)
    return (cases[value] or (cases.default or function() end))()
end

---@type string
local program
---@type thread
local program_thread
---@type boolean
local running = false
---@type table<number, boolean>
local breakpoints = {}
---@type table<number, string>
local bp_messages = {}

if args[1] then
    local file = io.open(args[1])
    if not file then
        print("Program not found: " .. args[1])
        os.exit(1)
    end
    file:close()
    program = args[1]
end

local function continue(...)
    local success, reason = coroutine.resume(program_thread, ...)

    if success then
        if coroutine.status(program_thread) == "dead" then
            running = false
            print(("Program finished. Return code %d"):format(reason or 0))
        else
            print("Breakpoint reached at line " .. reason.line)
            if #reason.message > 0 then
                io.write("Breakpoint value: ")

                if #reason.message == 1 then
                    print(reason.message[1])
                else
                    ---@param table table<any, any>
                    local function dump(table)
                        io.write("{")
                        for i,v in ipairs(table) do
                            switch(type(v), {
                                string = function()
                                    io.write(("%q"):format(v))
                                end,
                                table = function()
                                    dump(v)
                                end,
                            })
                            if i < #table then
                                io.write(", ")
                            end
                        end
                        print("}")
                    end

                    dump(reason.message)
                end
            end
        end
    else
        running = false
        print(reason)
    end
end

while true do
    io.write("(ldb) ")
    local input = io.read()

    local tokens = {}
    for token in input:gmatch("%S+") do
        table.insert(tokens, token)
    end

    local function pop()
        return table.remove(tokens, 1)
    end

    switch(pop(), {
        ["default"] = function()
            print("Unknown command")
        end,
        ["quit"] = function ()
            os.exit(0)
        end,
        ["load"] = function()
            program = pop()
        end,
        ["breakpoint"] = function()
            local line = tonumber(pop())
            if not line then
                print("Invalid line number")
                return
            end
            local msg = table.concat(tokens, " ")
            if msg == "" then
                bp_messages[line] = nil
                breakpoints[line] = not breakpoints[line]
            else
                bp_messages[line] = msg
                breakpoints[line] = true
            end
        end,
        ["breakpoints"] = function()
            for line, enabled in pairs(breakpoints) do
                print(("%d: %s %s"):format(line, enabled and "enabled" or "disabled", bp_messages[line] or ""))
            end
        end,
        ["run"] = function()
            if not program then
                print("No program loaded")
                return
            elseif running then
                print("Already running")
                return
            end

            local lines = {}
            for line in io.lines(program) do
                table.insert(lines, line)
            end

            do
                local offset = 0
                for breakpoint, enabled in pairs(breakpoints) do
                    if enabled then
                        table.insert(lines, breakpoint + offset, "coroutine.yield({type=\"breakpoint\", line=" .. breakpoint .. ", message={" .. (bp_messages[breakpoint] or "") .. "}})")
                        offset = offset + 1
                    end
                end
            end

            local chunk = table.concat(lines, "\n")
            local func, err = load(chunk, program, "t", _G)
            if not func then
                print(err)
                return
            end

            program_thread = coroutine.create(func)
            running = true
            continue(table.unpack(tokens))
        end,
        ["continue"] = function()
            if not running then
                print("Not running")
                return
            end
            continue(table.unpack(tokens))
        end,
        ["stop"] = function()
            running = false
            program_thread = nil
        end,
        ["trace"] = function()
            print(debug.traceback(program_thread))
        end,
        ["source"] = function()
            local what = pop()

            local file = io.open(program)
            local lines = {}
            for line in file:lines() do
                table.insert(lines, line)
            end
            file:close()

            local function print_source(line)
                if breakpoints[line] then
                    io.write("*")
                else
                    io.write(" ")
                end
                local fmt = "%" .. #tostring(#lines) .. "d: %s"
                print(fmt:format(line, lines[line]))
            end

            if what then
                print_source(tonumber(what))
            else
                for line = 1, #lines do
                    print_source(line)
                end
            end
        end
    })
end
