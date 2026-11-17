
local function getDefaults()
    local gyroFilterType = { [0] = "NONE", "1ST", "2ND" }
    local defaults = {}
    defaults.gyro_hardware_lpf = {}
    defaults.gyro_lpf1_type = { min = 0, max = #gyroFilterType, table = gyroFilterType }
    defaults.gyro_lpf1_static_hz = { min = 0, max = 4000, unit = gr.units.herz }
    defaults.gyro_lpf2_type = { min = 0, max = #gyroFilterType, table = gyroFilterType }
    defaults.gyro_lpf2_static_hz = { min = 0, max = 4000, unit = gr.units.herz }
    defaults.gyro_soft_notch_hz_1 = { min = 0, max = 4000, unit = gr.units.herz }
    defaults.gyro_soft_notch_cutoff_1 = { min = 0, max = 4000, unit = gr.units.herz }
    defaults.gyro_soft_notch_hz_2 = { min = 0, max = 4000, unit = gr.units.herz }
    defaults.gyro_soft_notch_cutoff_2 = { min = 0, max = 4000, unit = gr.units.herz }
    defaults.gyro_lpf1_dyn_min_hz = { min = 0, max = 1000, unit = gr.units.herz }
    defaults.gyro_lpf1_dyn_max_hz = { min = 0, max = 1000, unit = gr.units.herz }
    defaults.dyn_notch_count = { min = 0, max = 8 }
    defaults.dyn_notch_q = { min = 10, max = 100, scale = 10 }
    defaults.dyn_notch_min_hz = { min = 10, max = 200, unit = gr.units.herz }
    defaults.dyn_notch_max_hz = { min = 100, max = 500, unit = gr.units.herz }
    if gr.apiVersion >= 22.04 then
        defaults.preset = { min = 0, max = 3 }
        defaults.min_hz = { min = 1, max = 100, unit = gr.units.herz }
    end
    return defaults
end

local function getFilterConfig(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 92, -- MSP_FILTER_CONFIG
        processReply = function(self, buf)
            data.gyro_hardware_lpf.value = gr.mspHelper.readU8(buf)
            data.gyro_lpf1_type.value = gr.mspHelper.readU8(buf)
            data.gyro_lpf1_static_hz.value = gr.mspHelper.readU16(buf)
            data.gyro_lpf2_type.value = gr.mspHelper.readU8(buf)
            data.gyro_lpf2_static_hz.value = gr.mspHelper.readU16(buf)
            data.gyro_soft_notch_hz_1.value = gr.mspHelper.readU16(buf)
            data.gyro_soft_notch_cutoff_1.value = gr.mspHelper.readU16(buf)
            data.gyro_soft_notch_hz_2.value = gr.mspHelper.readU16(buf)
            data.gyro_soft_notch_cutoff_2.value = gr.mspHelper.readU16(buf)
            data.gyro_lpf1_dyn_min_hz.value = gr.mspHelper.readU16(buf)
            data.gyro_lpf1_dyn_max_hz.value = gr.mspHelper.readU16(buf)
            data.dyn_notch_count.value = gr.mspHelper.readU8(buf)
            data.dyn_notch_q.value = gr.mspHelper.readU8(buf)
            data.dyn_notch_min_hz.value = gr.mspHelper.readU16(buf)
            data.dyn_notch_max_hz.value = gr.mspHelper.readU16(buf)
            if gr.apiVersion >= 22.04 then
                data.preset.value = gr.mspHelper.readU8(buf)
                data.min_hz.value = gr.mspHelper.readU8(buf)
            end
            callback(callbackParam, data)
        end,
        simulatorResponse = { 0, 1, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 25, 25, 0, 245, 0, 0, 0 },
    }
    gr.mspQueue:add(message)
end

local function setFilterConfig(data)
    local message = {
        command = 93, -- MSP_SET_FILTER_CONFIG
        payload = {},
        simulatorResponse = {}
    }
    gr.mspHelper.writeU8(message.payload, data.gyro_hardware_lpf.value)
    gr.mspHelper.writeU8(message.payload, data.gyro_lpf1_type.value)
    gr.mspHelper.writeU16(message.payload, data.gyro_lpf1_static_hz.value)
    gr.mspHelper.writeU8(message.payload, data.gyro_lpf2_type.value)
    gr.mspHelper.writeU16(message.payload, data.gyro_lpf2_static_hz.value)
    gr.mspHelper.writeU16(message.payload, data.gyro_soft_notch_hz_1.value)
    gr.mspHelper.writeU16(message.payload, data.gyro_soft_notch_cutoff_1.value)
    gr.mspHelper.writeU16(message.payload, data.gyro_soft_notch_hz_2.value)
    gr.mspHelper.writeU16(message.payload, data.gyro_soft_notch_cutoff_2.value)
    gr.mspHelper.writeU16(message.payload, data.gyro_lpf1_dyn_min_hz.value)
    gr.mspHelper.writeU16(message.payload, data.gyro_lpf1_dyn_max_hz.value)
    gr.mspHelper.writeU8(message.payload, data.dyn_notch_count.value)
    gr.mspHelper.writeU8(message.payload, data.dyn_notch_q.value)
    gr.mspHelper.writeU16(message.payload, data.dyn_notch_min_hz.value)
    gr.mspHelper.writeU16(message.payload, data.dyn_notch_max_hz.value)
    if gr.apiVersion >= 22.04 then
        gr.mspHelper.writeU8(message.payload, data.preset.value)
        gr.mspHelper.writeU8(message.payload, data.min_hz.value)
    end
    gr.mspQueue:add(message)
end

return {
    read = getFilterConfig,
    write = setFilterConfig,
    getDefaults = getDefaults
}
