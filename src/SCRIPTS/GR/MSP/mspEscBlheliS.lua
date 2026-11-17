local onOff = {
    [0] = "Off",
    "On",
}

local startupPower = {
    [0] = "0.031",
    "0.047",
    "0.063",
    "0.094",
    "0.125",
    "0.188",
    "0.25",
    "0.38",
    "0.50",
    "0.75",
    "1.00",
    "1.25",
    "1.50",
}

local motorDirection = {
    [0] = "Normal",
    "Reversed",
    "Forward/Reverse (3D)",
    "Forward/Reverse (3D) Rev",
}

local commutationTiming = {
    [0] = "Low",
    "Medium Low",
    "Medium",
    "Medium High",
    "High",
}

local demagCompensation = {
    [0] = "Off",
    "Low",
    "High",
}

local beaconDelay = {
    [0] = "1 minute",
    "2 minutes",
    "5 minutes",
    "10 minutes",
    "Infinite",
}

local temperatureProtection = {
    [0] = "Disabled",
    "80 C",
    "90 C",
    "100 C",
    "110 C",
    "120 C",
    "130 C",
    "140 C",
}

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function normalizePpm(raw)
    if raw == nil then return nil end
    return raw * 4 + 1000
end

local function encodePpm(value)
    if value == nil then return nil end
    return clamp(math.floor(((value - 1000) / 4) + 0.5), 0, 255)
end

local function getFirmwareVersion(major, minor)
    if not(major and minor) then return "UNKNOWN" end
    return string.format("Firmware: %d.%d", major, minor)
end

local function getDefaults()
    local d = {}
    d.esc_signature = nil
    d.esc_command = nil
    d.main_revision = nil
    d.sub_revision = nil
    d.layout_revision = nil
    d.p_gain = nil
    d.i_gain = nil
    d.governor_mode = nil
    d.low_voltage_limit = nil
    d.motor_gain = nil
    d.motor_idle = nil
    d.startup_power = { min = 0, max = #startupPower, table = startupPower }
    d.pwm_frequency = nil
    d.motor_direction = { min = 0, max = #motorDirection, table = motorDirection }
    d.input_pwm_polarity = nil
    d.mode_raw = nil
    d.programming_by_tx = { min = 0, max = #onOff, table = onOff }
    d.rearm_at_start = nil
    d.governor_setup_target = nil
    d.startup_rpm = nil
    d.startup_acceleration = nil
    d.volt_comp = nil
    d.commutation_timing = { min = 0, max = #commutationTiming, table = commutationTiming }
    d.damping_force = nil
    d.governor_range = nil
    d.startup_method = nil
    d.ppm_min_throttle = { min = 1000, max = 1500, mult = 4 }
    d.ppm_max_throttle = { min = 1504, max = 2020, mult = 4 }
    d.beep_strength = { min = 1, max = 255 }
    d.beacon_strength = { min = 1, max = 255 }
    d.beacon_delay = { min = 0, max = #beaconDelay, table = beaconDelay }
    d.throttle_rate = nil
    d.demag_compensation = { min = 0, max = #demagCompensation, table = demagCompensation }
    d.bec_voltage = nil
    d.ppm_center_throttle = { min = 1000, max = 2020, mult = 4 }
    d.spoolup_time = nil
    d.temperature_protection = { min = 0, max = #temperatureProtection, table = temperatureProtection }
    d.low_rpm_power_protection = { min = 0, max = #onOff, table = onOff }
    d.pwm_input = nil
    d.pwm_dither = nil
    d.brake_on_stop = { min = 0, max = #onOff, table = onOff }
    d.led_control = nil
    d.reserved_29 = nil
    d.reserved_2a_2b = nil
    d.reserved_2c_2f = nil
    d.reserved_30_33 = nil
    d.reserved_34_37 = nil
    d.reserved_38_3b = nil
    d.reserved_3c_3f = nil
    return d
end

local function getEscParameters(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 217, -- MSP_ESC_PARAMETERS
        ignoreErrors = true, -- it usually works after a few errors (?)
        processReply = function(self, buf)
            local signature = gr.mspHelper.readU8(buf)
            if signature ~= 193 then
                return
            end

            data.esc_signature = signature
            data.esc_command = gr.mspHelper.readU8(buf)
            data.main_revision = gr.mspHelper.readU8(buf)
            if data.main_revision ~= 16 then
                return
            end
            data.sub_revision = gr.mspHelper.readU8(buf)
            data.layout_revision = gr.mspHelper.readU8(buf)
            data.p_gain = gr.mspHelper.readU8(buf)
            data.i_gain = gr.mspHelper.readU8(buf)
            data.governor_mode = gr.mspHelper.readU8(buf)
            data.low_voltage_limit = gr.mspHelper.readU8(buf)
            data.motor_gain = gr.mspHelper.readU8(buf)
            data.motor_idle = gr.mspHelper.readU8(buf)
            data.startup_power.value = gr.mspHelper.readU8(buf) - 1
            data.pwm_frequency = gr.mspHelper.readU8(buf)
            data.motor_direction.value = gr.mspHelper.readU8(buf) - 1
            data.input_pwm_polarity = gr.mspHelper.readU8(buf)
            data.mode_raw = gr.mspHelper.readU16(buf)
            data.programming_by_tx.value = gr.mspHelper.readU8(buf)
            data.rearm_at_start = gr.mspHelper.readU8(buf)
            data.governor_setup_target = gr.mspHelper.readU8(buf)
            data.startup_rpm = gr.mspHelper.readU8(buf)
            data.startup_acceleration = gr.mspHelper.readU8(buf)
            data.volt_comp = gr.mspHelper.readU8(buf)
            data.commutation_timing.value = gr.mspHelper.readU8(buf) - 1
            data.damping_force = gr.mspHelper.readU8(buf)
            data.governor_range = gr.mspHelper.readU8(buf)
            data.startup_method = gr.mspHelper.readU8(buf)
            data.ppm_min_throttle.value = normalizePpm(gr.mspHelper.readU8(buf))
            data.ppm_max_throttle.value = normalizePpm(gr.mspHelper.readU8(buf))
            data.beep_strength.value = gr.mspHelper.readU8(buf)
            data.beacon_strength.value = gr.mspHelper.readU8(buf)
            data.beacon_delay.value = gr.mspHelper.readU8(buf) - 1
            data.throttle_rate = gr.mspHelper.readU8(buf)
            data.demag_compensation.value = gr.mspHelper.readU8(buf) - 1
            data.bec_voltage = gr.mspHelper.readU8(buf)
            data.ppm_center_throttle.value = normalizePpm(gr.mspHelper.readU8(buf))
            data.spoolup_time = gr.mspHelper.readU8(buf)
            data.temperature_protection.value = gr.mspHelper.readU8(buf)
            data.low_rpm_power_protection.value = gr.mspHelper.readU8(buf)
            data.pwm_input = gr.mspHelper.readU8(buf)
            data.pwm_dither = gr.mspHelper.readU8(buf)
            data.brake_on_stop.value = gr.mspHelper.readU8(buf)
            data.led_control = gr.mspHelper.readU8(buf)
            data.reserved_29 = gr.mspHelper.readU8(buf)
            data.reserved_2a_2b = gr.mspHelper.readU16(buf)
            data.reserved_2c_2f = gr.mspHelper.readU32(buf)
            data.reserved_30_33 = gr.mspHelper.readU32(buf)
            data.reserved_34_37 = gr.mspHelper.readU32(buf)
            data.reserved_38_3b = gr.mspHelper.readU32(buf)
            data.reserved_3c_3f = gr.mspHelper.readU32(buf)

            -- Derived fields
            data.firmwareVersion = getFirmwareVersion(data.main_revision, data.sub_revision)

            callback(callbackParam, data)
        end,

        simulatorResponse = { 193, 0, 16, 7, 33, 255, 255, 255, 255, 255, 255, 10, 255, 3, 255, 85, 170, 1, 255, 255, 255, 255, 255, 3, 255, 255, 255, 37, 208, 40, 80, 4, 255, 2, 255, 122, 255, 7, 1, 255, 255, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 },
    }
    gr.mspQueue:add(message)
end

local function setEscParameters(data)
    local message = {
        command = 218, -- MSP_SET_ESC_PARAMETERS
        retryDelay = 2,
        postSendDelay = 2,
        payload = {}
    }

    gr.mspHelper.writeU8(message.payload, data.esc_signature)
    gr.mspHelper.writeU8(message.payload, data.esc_command)
    gr.mspHelper.writeU8(message.payload, data.main_revision)
    gr.mspHelper.writeU8(message.payload, data.sub_revision)
    gr.mspHelper.writeU8(message.payload, data.layout_revision)
    gr.mspHelper.writeU8(message.payload, data.p_gain)
    gr.mspHelper.writeU8(message.payload, data.i_gain)
    gr.mspHelper.writeU8(message.payload, data.governor_mode)
    gr.mspHelper.writeU8(message.payload, data.low_voltage_limit)
    gr.mspHelper.writeU8(message.payload, data.motor_gain)
    gr.mspHelper.writeU8(message.payload, data.motor_idle)
    gr.mspHelper.writeU8(message.payload, data.startup_power.value + 1)
    gr.mspHelper.writeU8(message.payload, data.pwm_frequency)
    gr.mspHelper.writeU8(message.payload, data.motor_direction.value + 1)
    gr.mspHelper.writeU8(message.payload, data.input_pwm_polarity)
    gr.mspHelper.writeU16(message.payload, data.mode_raw)
    gr.mspHelper.writeU8(message.payload, data.programming_by_tx.value)
    gr.mspHelper.writeU8(message.payload, data.rearm_at_start)
    gr.mspHelper.writeU8(message.payload, data.governor_setup_target)
    gr.mspHelper.writeU8(message.payload, data.startup_rpm)
    gr.mspHelper.writeU8(message.payload, data.startup_acceleration)
    gr.mspHelper.writeU8(message.payload, data.volt_comp)
    gr.mspHelper.writeU8(message.payload, data.commutation_timing.value + 1)
    gr.mspHelper.writeU8(message.payload, data.damping_force)
    gr.mspHelper.writeU8(message.payload, data.governor_range)
    gr.mspHelper.writeU8(message.payload, data.startup_method)
    gr.mspHelper.writeU8(message.payload, encodePpm(data.ppm_min_throttle.value))
    gr.mspHelper.writeU8(message.payload, encodePpm(data.ppm_max_throttle.value))
    gr.mspHelper.writeU8(message.payload, data.beep_strength.value)
    gr.mspHelper.writeU8(message.payload, data.beacon_strength.value)
    gr.mspHelper.writeU8(message.payload, data.beacon_delay.value + 1)
    gr.mspHelper.writeU8(message.payload, data.throttle_rate)
    gr.mspHelper.writeU8(message.payload, data.demag_compensation.value + 1)
    gr.mspHelper.writeU8(message.payload, data.bec_voltage)
    gr.mspHelper.writeU8(message.payload, encodePpm(data.ppm_center_throttle.value))
    gr.mspHelper.writeU8(message.payload, data.spoolup_time)
    gr.mspHelper.writeU8(message.payload, data.temperature_protection.value)
    gr.mspHelper.writeU8(message.payload, data.low_rpm_power_protection.value)
    gr.mspHelper.writeU8(message.payload, data.pwm_input)
    gr.mspHelper.writeU8(message.payload, data.pwm_dither)
    gr.mspHelper.writeU8(message.payload, data.brake_on_stop.value)
    gr.mspHelper.writeU8(message.payload, data.led_control)
    gr.mspHelper.writeU8(message.payload, data.reserved_29)
    gr.mspHelper.writeU16(message.payload, data.reserved_2a_2b)
    gr.mspHelper.writeU32(message.payload, data.reserved_2c_2f)
    gr.mspHelper.writeU32(message.payload, data.reserved_30_33)
    gr.mspHelper.writeU32(message.payload, data.reserved_34_37)
    gr.mspHelper.writeU32(message.payload, data.reserved_38_3b)
    gr.mspHelper.writeU32(message.payload, data.reserved_3c_3f)

    gr.mspQueue:add(message)
end

return {
    read = getEscParameters,
    write = setEscParameters,
    getDefaults = getDefaults
}









