local function deleteOrTruncateFile(filepath)
    local file = io.open(filepath, "r")
    if file then
        io.close(file)
        if del then
            -- EdgeTX 2.9+: delete file
            del(filepath)
            return
        end
        -- Older EdgeTX/OpenTX: truncate file
        file = io.open(filepath, "w")
        io.close(file)
    end
end

-- The grtlm mixer script has been incorporated in grbg.lua and is now stored in GR.
-- Leaving grtlm.lua in MIXES will conflict with grbg.lua if enabled.
deleteOrTruncateFile("/SCRIPTS/MIXES/grtlm.lua")
deleteOrTruncateFile("/SCRIPTS/MIXES/grtlm.luac")

local i = 1

local function compile()
    script = assert(loadScript("/SCRIPTS/GR/COMPILE/scripts.lua"))(i)
    collectgarbage()
    i = i + 1
    if script then
        lcd.clear()
        lcd.drawText(2, 2, "Compiling...", SMLSIZE)
        lcd.drawText(2, 58, script, SMLSIZE)
        assert(loadScript(script, 'cd')) -- The 'd' flags gets removed in by minimize.lua
        return 0
    end
    local file = io.open("/SCRIPTS/GR/COMPILE/scripts_compiled.lua", 'w')
    io.write(file, "return true")
    io.close(file)
    assert(loadScript("/SCRIPTS/GR/COMPILE/scripts_compiled.lua", 'c'))
    return 1
end

return compile
