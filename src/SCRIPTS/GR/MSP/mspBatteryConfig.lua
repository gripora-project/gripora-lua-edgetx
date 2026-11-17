local function getDefaults()
    local defaults = {}
    if gr.apiVersion < 22.04 then
        defaults.batteryCapacity = { min = 0, max = 20000, mult = 25, unit = gr.units.mah }
    end
    defaults.batteryCellCount = { min = 0, max = 24 }
    defaults.voltageMeterSource = { min = 0, max = 3, table = { [0] = "None", "ADC", "ESC" } }
    defaults.currentMeterSource = { min = 0, max = 3, table = { [0] = "None", "ADC", "ESC" } }
    defaults.vbatmincellvoltage = { min = 100, max = 500, scale = 100, unit =  gr.units.volt }
    defaults.vbatmaxcellvoltage = { min = 100, max = 500, scale = 100, unit =  gr.units.volt }
    defaults.vbatfullcellvoltage = { min = 100, max = 500, scale = 100, unit =  gr.units.volt }
    defaults.vbatwarningcellvoltage = { min = 100, max = 500, scale = 100, unit =  gr.units.volt }
    defaults.lvcPercentage = { min = 0, max = 100, unit = gr.units.percentage }
    defaults.consumptionWarningPercentage = { min = 0, max = 100, unit = gr.units.percentage }
    if gr.apiVersion >= 22.04 then
        defaults.batteryCapacity = { }
        defaults.profileCellCount = {}
        defaults.profileMinCellVoltage = {}
        defaults.profileMaxCellVoltage = {}
        defaults.profileFullCellVoltage = {}
        defaults.profileWarningCellVoltage = {}
        for i = 0, 5 do
            defaults.batteryCapacity[i] = { min = 0, max = 20000, mult = 25, units = gr.units.mah }
        end
    end

    return defaults
end

local function getBatteryConfig(callback, callbackParam, config)
    if not config then config = getDefaults() end
    local message = {
        command = 32, -- MSP_BATTERY_CONFIG
        processReply = function(self, buf)
            local activeBatteryCapacity =  gr.mspHelper.readU16(buf)
            if gr.apiVersion < 22.04 then
                config.batteryCapacity.value = activeBatteryCapacity
            end
            config.batteryCellCount.value = gr.mspHelper.readU8(buf)
            config.voltageMeterSource.value = gr.mspHelper.readU8(buf)
            config.currentMeterSource.value = gr.mspHelper.readU8(buf)
            config.vbatmincellvoltage.value = gr.mspHelper.readU16(buf)
            config.vbatmaxcellvoltage.value = gr.mspHelper.readU16(buf)
            config.vbatfullcellvoltage.value = gr.mspHelper.readU16(buf)
            config.vbatwarningcellvoltage.value = gr.mspHelper.readU16(buf)
            config.lvcPercentage.value = gr.mspHelper.readU8(buf)
            config.consumptionWarningPercentage.value = gr.mspHelper.readU8(buf)
            if gr.apiVersion >= 22.04 then
                for i = 0, 5 do
                    config.batteryCapacity[i].value = gr.mspHelper.readU16(buf)
                end
                if #buf >= 81 then
                    for i = 0, 5 do
                        config.profileCellCount[i] = gr.mspHelper.readU8(buf)
                    end
                    for i = 0, 5 do
                        config.profileMinCellVoltage[i] = gr.mspHelper.readU16(buf)
                    end
                    for i = 0, 5 do
                        config.profileMaxCellVoltage[i] = gr.mspHelper.readU16(buf)
                    end
                    for i = 0, 5 do
                        config.profileFullCellVoltage[i] = gr.mspHelper.readU16(buf)
                    end
                    for i = 0, 5 do
                        config.profileWarningCellVoltage[i] = gr.mspHelper.readU16(buf)
                    end
                end
            end
            if callback then callback(callbackParam, config) end
        end,
        simulatorResponse = {
            184, 11, 12, 2, 2, 64, 1, 174, 1, 154, 1, 94, 1, 100, 10,
            152, 8, 184, 11, 172, 13, 160, 15,
            12, 12, 12, 12, 12, 12,
            64, 1, 64, 1, 64, 1, 64, 1, 64, 1, 64, 1,
            174, 1, 174, 1, 174, 1, 174, 1, 174, 1, 174, 1,
            154, 1, 154, 1, 154, 1, 154, 1, 154, 1, 154, 1,
            94, 1, 94, 1, 94, 1, 94, 1, 94, 1, 94, 1
        }
    }
    gr.mspQueue:add(message)
end

local function setBatteryConfig(config)
    local message = {
        command = 33, -- MSP_SET_BATTERY_CONFIG
        payload = {},
        simulatorResponse = {}
    }
    if gr.apiVersion < 22.04 then
        gr.mspHelper.writeU16(message.payload, config.batteryCapacity.value)
    else
        gr.mspHelper.writeU16(message.payload, config.batteryCapacity[0].value) -- will be overwritten later
    end
    gr.mspHelper.writeU8(message.payload, config.batteryCellCount.value)
    gr.mspHelper.writeU8(message.payload, config.voltageMeterSource .value)
    gr.mspHelper.writeU8(message.payload, config.currentMeterSource .value)
    gr.mspHelper.writeU16(message.payload, config.vbatmincellvoltage .value)
    gr.mspHelper.writeU16(message.payload, config.vbatmaxcellvoltage .value)
    gr.mspHelper.writeU16(message.payload, config.vbatfullcellvoltage .value)
    gr.mspHelper.writeU16(message.payload, config.vbatwarningcellvoltage .value)
    gr.mspHelper.writeU8(message.payload, config.lvcPercentage .value)
    gr.mspHelper.writeU8(message.payload, config.consumptionWarningPercentage .value)
    if gr.apiVersion >= 22.04 then
        local profile = config.activeBatteryProfile
        if profile then
            config.profileCellCount[profile] = config.batteryCellCount.value
            config.profileMinCellVoltage[profile] = config.vbatmincellvoltage.value
            config.profileMaxCellVoltage[profile] = config.vbatmaxcellvoltage.value
            config.profileFullCellVoltage[profile] = config.vbatfullcellvoltage.value
            config.profileWarningCellVoltage[profile] = config.vbatwarningcellvoltage.value
        end
        for i = 0, 5 do
            gr.mspHelper.writeU16(message.payload, config.batteryCapacity[i].value)
        end
        for i = 0, 5 do
            gr.mspHelper.writeU8(message.payload, config.profileCellCount[i] or config.batteryCellCount.value)
        end
        for i = 0, 5 do
            gr.mspHelper.writeU16(message.payload, config.profileMinCellVoltage[i] or config.vbatmincellvoltage.value)
        end
        for i = 0, 5 do
            gr.mspHelper.writeU16(message.payload, config.profileMaxCellVoltage[i] or config.vbatmaxcellvoltage.value)
        end
        for i = 0, 5 do
            gr.mspHelper.writeU16(message.payload, config.profileFullCellVoltage[i] or config.vbatfullcellvoltage.value)
        end
        for i = 0, 5 do
            gr.mspHelper.writeU16(message.payload, config.profileWarningCellVoltage[i] or config.vbatwarningcellvoltage.value)
        end
    end

    gr.mspQueue:add(message)
end

return {
    read = getBatteryConfig,
    write = setBatteryConfig,
    getDefaults = getDefaults
}
