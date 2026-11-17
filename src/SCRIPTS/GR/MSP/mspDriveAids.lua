-- MSP2_GRIPORA_DRIVE_AIDS_CONFIG (0x5F3F read / 0x5F40 write): the drive aids
-- settings (firmware pg/drive_aids.h), ABS first. All fields are U8. Later
-- aids append fields to the reply, so only the first 9 bytes are read; the
-- write sends exactly these 9 and the firmware leaves the rest unchanged.
-- The firmware refuses the whole write if any value is out of range.
local function getDefaults()
    local defaults = {}
    defaults.abs_mode = { min = 0, max = 2, table = { [0] = "Off", "Static", "Dynamic" } }
    defaults.abs_freq = { min = 2, max = 33, unit = gr.units.herz }
    defaults.abs_floor = { min = 0, max = 100, unit = gr.units.percentage }
    defaults.abs_hold = { min = 0, max = 100, unit = gr.units.milliseconds }
    defaults.abs_trigger = { min = 5, max = 100, unit = gr.units.percentage }
    defaults.abs_dyn_freq = { min = 2, max = 33, unit = gr.units.herz }
    defaults.abs_dyn_hold = { min = 0, max = 100, unit = gr.units.milliseconds }
    defaults.abs_corner_freq = { min = 0, max = 10, unit = gr.units.herz }
    defaults.abs_corner_hold = { min = 0, max = 100, unit = gr.units.milliseconds }
    return defaults
end

-- errorCallback runs on the FC's MSP error reply: firmware without the message.
local function getDriveAidsConfig(callback, callbackParam, data, errorCallback)
    data = data or getDefaults()
    local message = {
        command = 0x5F3F, -- MSP2_GRIPORA_DRIVE_AIDS_CONFIG
        processReply = function(self, buf)
            if #buf < 9 then
                if errorCallback then errorCallback(callbackParam) end
                return
            end
            data.abs_mode.value = gr.mspHelper.readU8(buf)
            data.abs_freq.value = gr.mspHelper.readU8(buf)
            data.abs_floor.value = gr.mspHelper.readU8(buf)
            data.abs_hold.value = gr.mspHelper.readU8(buf)
            data.abs_trigger.value = gr.mspHelper.readU8(buf)
            data.abs_dyn_freq.value = gr.mspHelper.readU8(buf)
            data.abs_dyn_hold.value = gr.mspHelper.readU8(buf)
            data.abs_corner_freq.value = gr.mspHelper.readU8(buf)
            data.abs_corner_hold.value = gr.mspHelper.readU8(buf)
            callback(callbackParam, data)
        end,
        errorHandler = function(self)
            if errorCallback then errorCallback(callbackParam) end
        end,
        simulatorResponse = { 0, 10, 40, 20, 30, 15, 0, 0, 0 }
    }
    gr.mspQueue:add(message)
end

local function setDriveAidsConfig(config)
    local message = {
        command = 0x5F40, -- MSP2_GRIPORA_SET_DRIVE_AIDS_CONFIG
        payload = {},
        simulatorResponse = {}
    }
    gr.mspHelper.writeU8(message.payload, config.abs_mode.value)
    gr.mspHelper.writeU8(message.payload, config.abs_freq.value)
    gr.mspHelper.writeU8(message.payload, config.abs_floor.value)
    gr.mspHelper.writeU8(message.payload, config.abs_hold.value)
    gr.mspHelper.writeU8(message.payload, config.abs_trigger.value)
    gr.mspHelper.writeU8(message.payload, config.abs_dyn_freq.value)
    gr.mspHelper.writeU8(message.payload, config.abs_dyn_hold.value)
    gr.mspHelper.writeU8(message.payload, config.abs_corner_freq.value)
    gr.mspHelper.writeU8(message.payload, config.abs_corner_hold.value)
    gr.mspQueue:add(message)
end

return {
    read = getDriveAidsConfig,
    write = setDriveAidsConfig,
    getDefaults = getDefaults
}
