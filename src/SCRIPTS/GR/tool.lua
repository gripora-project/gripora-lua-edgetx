chdir("/SCRIPTS/GR")

local run = nil
local scriptsCompiled = assert(loadScript("COMPILE/scripts_compiled.lua"))()
local useLvgl = false

if scriptsCompiled then
    --print("GR: Before gr.lua: ", collectgarbage("count") * 1024)
    assert(loadScript("gr.lua"))()
    --gr.showMemoryUsage("gr loaded")
    gr.radio = gr.executeScript("radios")
    gr.mspQueue = gr.executeScript("MSP/mspQueue")
    gr.mspHelper = gr.executeScript("MSP/mspHelper")

    local canUseLvgl = gr.executeScript("F/canUseLvgl")()
    if canUseLvgl then
        local settings = gr.loadSettings()
        if settings["useLvgl"] == nil or settings["useLvgl"] == 1 then useLvgl = true end
    end

    if useLvgl then
        run = gr.executeScript("ui_lvgl_runner")
    else
        run = gr.executeScript("ui_lcd")
    end

    gr.isTool = true
else
    run = assert(loadScript("COMPILE/compile.lua"))()
    collectgarbage()
end

return { run = run, useLvgl = useLvgl }
