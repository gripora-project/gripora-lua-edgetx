-- MSP2_GRIPORA_DRIFT_CONFIG (0x5F42 read / 0x5F43 write): the DRIFT mode
-- settings of the current PID profile (firmware pg/drift.h): U8 counter-steer
-- gain %, U16 allowed turn rate deg/s, U8 counter-steer limit % of full lock.
-- The firmware refuses the whole write if any value is out of range.
local function getDefaults()
    local defaults = {}
    defaults.gain = { min = 0, max = 200, unit = gr.units.percentage }
    defaults.allow = { min = 0, max = 720, unit = gr.units.degreesPerSecond }
    defaults.limit = { min = 10, max = 100, unit = gr.units.percentage }
    return defaults
end

-- errorCallback runs on the FC's MSP error reply: firmware without the message.
local function getDriftConfig(callback, callbackParam, data, errorCallback)
    data = data or getDefaults()
    local message = {
        command = 0x5F42, -- MSP2_GRIPORA_DRIFT_CONFIG
        processReply = function(self, buf)
            if #buf < 4 then
                if errorCallback then errorCallback(callbackParam) end
                return
            end
            data.gain.value = gr.mspHelper.readU8(buf)
            data.allow.value = gr.mspHelper.readU16(buf)
            data.limit.value = gr.mspHelper.readU8(buf)
            callback(callbackParam, data)
        end,
        errorHandler = function(self)
            if errorCallback then errorCallback(callbackParam) end
        end,
        simulatorResponse = { 100, 30, 0, 100 }
    }
    gr.mspQueue:add(message)
end

local function setDriftConfig(config)
    local message = {
        command = 0x5F43, -- MSP2_GRIPORA_SET_DRIFT_CONFIG
        payload = {},
        simulatorResponse = {}
    }
    gr.mspHelper.writeU8(message.payload, config.gain.value)
    gr.mspHelper.writeU16(message.payload, config.allow.value)
    gr.mspHelper.writeU8(message.payload, config.limit.value)
    gr.mspQueue:add(message)
end

return {
    read = getDriftConfig,
    write = setDriftConfig,
    getDefaults = getDefaults
}
