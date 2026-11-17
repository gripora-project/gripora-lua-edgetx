local function getDefaults()
    local defaults = {}
    local protocolTable = { [0] = "NONE", "BLHELI32", "HOBBYWING V4", "HOBBYWING V5", "SCORPION", "KONTRONIK", "OMP", "ZTW", "APD", "OPENYGE", "FLYROTOR", "GRAUPNER", "XDFLY", "FrSky F.BUS", "SRXL2", "RECORD" }

    defaults.protocol = { min = 0, max = #protocolTable, table = protocolTable }
    defaults.half_duplex = { min = 0, max = 1, table = { [0] = "Off", "On" } }
    defaults.update_hz = { min = 10, max = 500, unit = gr.units.herz }
    defaults.current_offset = { min = 0, max = 16000 }
    defaults.pin_swap = { min = 0, max = 1, table = { [0] = "Off", "On" } }
    defaults.voltage_correction = { min = -100, max = 125, unit = gr.units.percentage }
    defaults.current_correction = { min = -100, max = 125, unit = gr.units.percentage }
    defaults.consumption_correction = { min = -100, max = 125, unit = gr.units.percentage }
    return defaults
end

local function getEscSensorConfig(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 123, -- MSP_ESC_SENSOR_CONFIG
        processReply = function(self, buf)
            data.protocol.value = gr.mspHelper.readU8(buf)
            data.half_duplex.value = gr.mspHelper.readU8(buf)
            data.update_hz.value = gr.mspHelper.readU16(buf)
            data.current_offset.value = gr.mspHelper.readU16(buf)
            data.pin_swap.value = gr.mspHelper.readU8(buf)
            data.voltage_correction.value = gr.mspHelper.readS8(buf)
            data.current_correction.value = gr.mspHelper.readS8(buf)
            data.consumption_correction.value = gr.mspHelper.readS8(buf)
            callback(callbackParam, data)
        end,
        simulatorResponse = { 0, 0, 200, 0, 15, 0, 0, 0, 0, 0 }
    }
    gr.mspQueue:add(message)
end

local function setEscSensorConfig(config)
    local message = {
        command = 216, -- MSP_SET_ESC_SENSOR_CONFIG
        payload = {},
        simulatorResponse = {}
    }
    gr.mspHelper.writeU8(message.payload, config.protocol.value)
    gr.mspHelper.writeU8(message.payload, config.half_duplex.value)
    gr.mspHelper.writeU16(message.payload, config.update_hz.value)
    gr.mspHelper.writeU16(message.payload, config.current_offset.value)
    gr.mspHelper.writeU8(message.payload, config.pin_swap.value)
    gr.mspHelper.writeU8(message.payload, config.voltage_correction.value)
    gr.mspHelper.writeU8(message.payload, config.current_correction.value)
    gr.mspHelper.writeU8(message.payload, config.consumption_correction.value)
    gr.mspQueue:add(message)
end

return {
    read = getEscSensorConfig,
    write = setEscSensorConfig,
    getDefaults = getDefaults
}
