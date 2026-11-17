gr = {
    luaVersion = "2.3.0",
    baseDir = "/SCRIPTS/GR/",
    runningInSimulator = string.sub(select(2, getVersion()), -4) == "simu",

    loadScript = function(script)
        local startsWith = function(str, prefix)
            return string.sub(str, 1, #prefix) == prefix
        end
        local endsWith = function(str, suffix)
            return suffix == "" or string.sub(str, -#suffix) == suffix
        end
        if not startsWith(script, gr.baseDir) then
            script = gr.baseDir .. script
        end
        if not endsWith(script, ".lua") then
            script = script .. ".lua"
        end
        collectgarbage()
        local result = loadScript(script)
        --gr.showMemoryUsage(script .. " loaded")
        return result
    end,

    executeScript = function(scriptName, ...)
        return assert(gr.loadScript(scriptName), scriptName)(...)
    end,

    useApi = function(apiName)
        return gr.executeScript("MSP/" .. apiName)
    end,

    loadSettings = function()
        return gr.executeScript("PAGES/helpers/settingsHelper").loadSettings();
    end,

    saveSettings = function(settings)
        return gr.executeScript("PAGES/helpers/settingsHelper").saveSettings(settings);
    end,

    clock = function()
        return getTime() / 100
    end,

    isEdgeTx = select(6, getVersion()) == "EdgeTX",

    apiVersion = nil,

    units = {
        percentage = "%",
        degrees = del and "°" or "@", -- OpenTX uses @
        degreesPerSecond = (del and "°" or "@") .. "/s",
        herz = " Hz",
        seconds = " s",
        milliseconds = " ms",
        volt = " V",
        celsius = " C",
        rpm = " RPM",
        meters = " m",
        mah = " mAh",
        percentagePerSecond = " %/s",
        millivoltsPerSecond = " mV/s",
        khz = " kHz",
        kv = " KV"
    },

    --[NIR
    formatTime = function(cs)
        local hours = math.floor(cs / 360000)
        cs = cs % 360000

        local minutes = math.floor(cs / 6000)
        cs = cs % 6000

        local seconds = math.floor(cs / 100)
        local centis = cs % 100

        return string.format("%02d:%02d:%02d:%02d", hours, minutes, seconds, centis)
    end,

    print = function(format, ...)
        local str = string.format("%s - GR: " .. tostring(format), gr.formatTime(getTime()), ...)
        if gr.runningInSimulator then
            print(str)
        else
            serialWrite(str .. "\r\n") -- 115200 bps
            --gr.log(str)
        end
    end,

    log = function(str)
        if gr.runningInSimulator then
            gr.print(tostring(str))
        else
            if not gr.logfile then
                gr.logfile = io.open("/LOGS/gr.log", "a")
            end
            io.write(gr.logfile, string.format("%.2f ", gr.clock()) .. tostring(str) .. "\n")
        end
    end,

    showMemoryUsage = function(remark)
        if not gr.oldMemoryUsage then
            collectgarbage()
            gr.oldMemoryUsage = collectgarbage("count")
            gr.print(string.format("MEM %s: %d", remark, gr.oldMemoryUsage*1024))
            return
        end
        collectgarbage()
        local currentMemoryUsage = collectgarbage("count")
        local increment = currentMemoryUsage - gr.oldMemoryUsage
        if increment ~= 0 then
            gr.print(string.format("MEM %s: %d (+%d)", remark, currentMemoryUsage*1024, increment*1024))
        end
        gr.oldMemoryUsage = currentMemoryUsage
    end,

    dumpTable = function(table, maxDepth)
        local seen = {}
        maxDepth = maxDepth or 2

        local function dumpTableInternal(tbl, indent, depth)
            if seen[tbl] or depth > maxDepth then
                gr.print(indent .. "*already visited or max depth*")
                return
            end
            seen[tbl] = true

            for k, v in pairs(tbl) do
                local keyStr = tostring(k)
                local vType = type(v)
                if vType == "table" then
                    gr.print(indent .. keyStr .. " = {")
                    dumpTableInternal(v, indent .. "  ", depth + 1)
                    gr.print(indent .. "}")
                else
                    gr.print(indent .. keyStr .. " = " .. tostring(v))
                end
            end
        end

        dumpTableInternal(table, "", 0)
    end,

    printGlobals = function(maxDepth)
        gr.dumpTable(_G, maxDepth)
    end,

    isInteger = function(n)
        return type(n) == "number" and n == math.floor(n)
    end,
    --]]

    call = function(func, ...)
        -- NOTE: 'gr.call' will be replaced by 'pcall' in release builds, see minimize.lua.
        -- This is done so all integration calls are protected.

        -- Use unprotected calls during development, so errors surface immediately.
        func(...)

        -- Or use protected calls and show any errors afterwards.
        -- local status, err = pcall(func, ...)
        -- if not status then gr.print(err) end
    end
}
