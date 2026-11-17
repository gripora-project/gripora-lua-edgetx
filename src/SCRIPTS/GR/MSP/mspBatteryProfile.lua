local function getDefaults()
    local defaults = {}
    defaults.batteryProfile = { min = 0, max = 5, table = { [0] = "1", "2", "3", "4", "5", "6" } }
    return defaults
end

local function getBatteryProfile(callback, callbackParam, config)
    if not config then config = getDefaults() end
    local message = {
        command = 175, -- MSP_BATTERY_PROFILE
        processReply = function(self, buf)
            config.batteryProfile.value = gr.mspHelper.readU8(buf)
            if callback then callback(callbackParam, config) end
        end,
        simulatorResponse = { 1 }
    }
    gr.mspQueue:add(message)
end

local function setBatteryProfile(config)
    local message = {
        command = 176, -- MSP_SET_BATTERY_PROFILE
        payload = {},
        simulatorResponse = {}
    }
    gr.mspHelper.writeU8(message.payload, config.batteryProfile.value)
    gr.mspQueue:add(message)
end

return {
    read = getBatteryProfile,
    write = setBatteryProfile,
    getDefaults = getDefaults
}
