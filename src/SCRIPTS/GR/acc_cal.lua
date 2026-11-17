local mspAccCalibration = gr.useApi("mspAccCalibration")
local sentCalibrate = false

local function calibrate()
    if not sentCalibrate then
        mspAccCalibration.calibrate()
        sentCalibrate = true
    end

    gr.mspQueue:processQueue()

    return gr.mspQueue:isProcessed()
end

return { f = calibrate, t = "Calibrating Accelerometer" }
