-- MSP2_GRIPORA_DRIVE_AIDS_CONFIG (0x5F3F read / 0x5F40 write): the drive aids
-- settings of the current PID profile (firmware pg/drive_aids.h): 9 ABS U8s,
-- then traction control (U8 mode, U16 ramp time ms), then launch control (U8
-- mode, U8 start throttle %, U16 ramp time ms). Older firmware replies with
-- 9 or 12 bytes; the missing values then stay nil and the write sends only
-- what was read (the firmware leaves the rest unchanged). Later aids append
-- fields; only the known ones are read. The firmware refuses the whole write
-- if any value is out of range.
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
    defaults.tc_mode = { min = 0, max = 1, table = { [0] = "Off", "Ramp" } }
    defaults.tc_ramp_time = { min = 50, max = 2000, mult = 10, unit = gr.units.milliseconds }
    defaults.lc_mode = { min = 0, max = 1, table = { [0] = "Off", "Switch" } }
    defaults.lc_throttle = { min = 10, max = 100, unit = gr.units.percentage }
    defaults.lc_ramp_time = { min = 100, max = 5000, mult = 10, unit = gr.units.milliseconds }
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
            if #buf >= 12 then
                data.tc_mode.value = gr.mspHelper.readU8(buf)
                data.tc_ramp_time.value = gr.mspHelper.readU16(buf)
            end
            if #buf >= 16 then
                data.lc_mode.value = gr.mspHelper.readU8(buf)
                data.lc_throttle.value = gr.mspHelper.readU8(buf)
                data.lc_ramp_time.value = gr.mspHelper.readU16(buf)
            end
            callback(callbackParam, data)
        end,
        errorHandler = function(self)
            if errorCallback then errorCallback(callbackParam) end
        end,
        simulatorResponse = { 0, 10, 40, 20, 30, 15, 0, 0, 0, 0, 244, 1, 0, 50, 232, 3 }
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
    if config.tc_mode.value then
        gr.mspHelper.writeU8(message.payload, config.tc_mode.value)
        gr.mspHelper.writeU16(message.payload, config.tc_ramp_time.value)
        if config.lc_mode.value then
            gr.mspHelper.writeU8(message.payload, config.lc_mode.value)
            gr.mspHelper.writeU8(message.payload, config.lc_throttle.value)
            gr.mspHelper.writeU16(message.payload, config.lc_ramp_time.value)
        end
    end
    gr.mspQueue:add(message)
end

return {
    read = getDriveAidsConfig,
    write = setDriveAidsConfig,
    getDefaults = getDefaults
}
