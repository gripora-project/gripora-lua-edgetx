local initialized = false
local backgroundTask = nil

local function startup()
    if not initialized then
        assert(loadScript("/SCRIPTS/GR/gr.lua"))()
        gr.mspQueue = gr.executeScript("MSP/mspQueue")
        gr.mspHelper = gr.executeScript("MSP/mspHelper")
        backgroundTask = gr.executeScript("background")
        initialized = true
    else
        backgroundTask()
    end
end

return { run = startup }
