local initTask = nil
local adjTellerTask = nil
local crsfTelemetryTask = nil
local frskyTelemetryTask = nil
local isInitialized = false
local modelIsConnected = false
local lastTimeRssi = nil

local function pilotConfigHasBeenReset()
    return model.getGlobalVariable(7, 8) == 0
end

local hasSensor = gr.executeScript("F/hasSensor")

local function setState(widget, state)
    if widget == nil then return end
    widget:setState(state)
end

local function run(widget)
    if isInitialized and crsfTelemetryTask and not hasSensor("*Cnt") then
        isInitialized = false -- user probably deleted all sensors on TX
    elseif getRSSI() > 0 then
        lastTimeRssi = gr.clock()
        modelIsConnected = true
        if isInitialized and pilotConfigHasBeenReset() then
            -- Since EdgeTX 2.11 the background script will resume execution instead of starting it again after running a tool.
            gr.mspQueue:clear()
            isInitialized = false
        end
    elseif getRSSI() == 0 then
        if lastTimeRssi and gr.clock() - lastTimeRssi < 5 then
            -- Do not re-initialise if the RSSI is 0 for less than 5 seconds.
            -- This is also a work-around for https://github.com/ExpressLRS/ExpressLRS/issues/3207 (AUX channel bug in ELRS TX < 3.5.5)
            -- setState(widget, "telemetry lost") -- also needs telemetry recoverede/connected
            return
        end
        if modelIsConnected then
            gr.executeScript("F/pilotConfigReset")()
            if initTask then
                initTask.reset()
                initTask = nil
            end
            adjTellerTask = nil
            crsfTelemetryTask = nil
            frskyTelemetryTask = nil
            modelIsConnected = false
            isInitialized = false
            collectgarbage()
        end
    end

    if not isInitialized then
        adjTellerTask = nil
        crsfTelemetryTask = nil
        frskyTelemetryTask = nil
        collectgarbage()
        initTask = initTask or gr.executeScript("background_init")
        local initTaskResult = initTask.run(modelIsConnected)
        if not initTaskResult.isInitialized then
            --gr.print("Not initialized yet")
            if getRSSI() == 0 then
                setState(widget, "disconnected")
            else
                setState(widget, "initializing")
            end
            return
        end
        if initTaskResult.crsfCustomTelemetryEnabled then
            local requestedSensorsBySid = gr.executeScript("grtlm_sensors", initTaskResult.crsfCustomTelemetrySensors)
            crsfTelemetryTask = gr.executeScript("grtlm", requestedSensorsBySid)
        elseif sportTelemetryPush() ~= nil then
            frskyTelemetryTask = gr.executeScript("grfrsky_tlm")
        end
        if initTask.useAdjustmentTeller then
            adjTellerTask = gr.executeScript("adj_teller")
        end
        initTask = nil
        isInitialized = true
        setState(widget, "connected")
    end

    if getRSSI() == 0 and not gr.runningInSimulator then
        return
    end

    if adjTellerTask and adjTellerTask.run() == 2  then
        -- no adjustment sensors found
        adjTellerTask = nil
    end

    if crsfTelemetryTask then
        crsfTelemetryTask.run()
    elseif frskyTelemetryTask then
        frskyTelemetryTask.run()
    end
end

-- widget is optional and will be provided by the GrTool widget.
-- If the background script runs as a special function, widget will be nil.
local function runProtected(widget)
    gr.call(run, widget)
    --collectgarbage()
    --gr.print("Mem: %d", collectgarbage("count")*1024)
    return 0
end

return runProtected
