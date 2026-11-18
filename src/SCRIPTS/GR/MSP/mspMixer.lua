-- Gripora's mixer is a generic rule-based system (MSP_MIXER_INPUTS/MSP_MIXER_RULES/
-- MSP_MIXER_CURVES below), not Rotorflight's helicopter swashplate mixer.

local MIXER_INPUT_COUNT = 36 -- MIXER_IN_COUNT (pg/mixer.h): NONE + 26 stabilized/RC-command/RC-channel inputs + 3 thrust-vector inputs + RC channels 19-24
local MIXER_OUTPUT_COUNT = 31 -- MIXER_OUTPUT_COUNT (flight/mixer.h): NONE + servos 1-24 + 2 reserved + 4 motors
local MIXER_RULE_COUNT = 32
local MIXER_CURVE_COUNT = 8
local MIXER_CURVE_POINTS = 9

-- Mixer rule outputs: 1-24 are the servos, 25 and 26 are reserved and 27-30 are the motors.
local MIXER_OUTPUT_RESERVED_FIRST = 25
local MIXER_OUTPUT_RESERVED_LAST = 26
local outputNames = { [0] = "None" }
for i = 1, 24 do outputNames[i] = "Servo " .. i end
for i = 1, 4 do outputNames[26 + i] = "Motor " .. i end

-- Servo outputs with their names (mspServos.getServoNames()): "Servo 1 (L AIL)".
-- names may be nil (firmware without servo names). The rule fields share this table.
-- Not on the 128 px wide screens: the value column has room for about 7 characters.
local function setServoNames(names)
    if LCD_W and LCD_W < 200 then return end
    for i = 1, 24 do
        local name = names and names[i - 1]
        if name and name ~= "" then
            outputNames[i] = "Servo " .. i .. " (" .. name .. ")"
        else
            outputNames[i] = "Servo " .. i
        end
    end
end

local function getDefaults()
    local defaults = {}
    -- MODEL_TYPE_* (pg/mixer.h)
    defaults.model_type = { min = 0, max = 1, table = { [0] = "Car", "Custom" } }
    return defaults
end

-- MSP_MIXER_CONFIG: U8 model_type, U8 reserved, U8 SBUS output channels, U8 F.Bus output
-- channels, U8 channels the configured bus output drives, U16 servo_pwm_rate (API 22.16).
local function getMixerConfig(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 42, -- MSP_MIXER_CONFIG
        processReply = function(self, buf)
            data.model_type.value = gr.mspHelper.readU8(buf)
            if #buf >= 7 then
                gr.mspHelper.readU8(buf) -- reserved
                data.sbus_out_channels = gr.mspHelper.readU8(buf)
                data.fbus_master_channels = gr.mspHelper.readU8(buf)
                gr.mspHelper.readU8(buf) -- channels the configured bus output drives
                data.servo_pwm_rate = gr.mspHelper.readU16(buf)
            end
            callback(callbackParam, data)
        end,
        simulatorResponse = { 0, 0, 16, 16, 0, 50, 0 },
    }
    gr.mspQueue:add(message)
end

-- The PWM rate comes after the two bus channel counts, so they are sent back as read.
-- Without them (the reply was not read in full) only the model type is written.
local function setMixerConfig(data)
    local message = {
        command = 43, -- MSP_SET_MIXER_CONFIG
        payload = {}
    }
    gr.mspHelper.writeU8(message.payload, data.model_type.value)
    gr.mspHelper.writeU8(message.payload, 0) -- reserved
    if data.servo_pwm_rate then
        gr.mspHelper.writeU8(message.payload, data.sbus_out_channels)
        gr.mspHelper.writeU8(message.payload, data.fbus_master_channels)
        gr.mspHelper.writeU16(message.payload, data.servo_pwm_rate)
    end
    gr.mspQueue:add(message)
end

-- Per-input stabilized-axis gain/limits, one entry per MIXER_IN_* enum value in the
-- firmware (stabilized roll/pitch/yaw/throttle, RC command roll/pitch/yaw/throttle,
-- RC channel roll/pitch/yaw/throttle/aux1-3/8-18). Always a fixed MIXER_INPUT_COUNT-size
-- array on the wire; there's no per-input "hidden" flag, all 26 slots are always sent.

local function getMixerInputs(callback, callbackParam)
    local message = {
        command = 170, -- MSP_MIXER_INPUTS
        processReply = function(self, buf)
            local inputs = {}
            for i = 0, MIXER_INPUT_COUNT - 1 do
                inputs[i] = {
                    rate = { value = gr.mspHelper.readS16(buf), min = -2500, max = 2500 },
                    min = { value = gr.mspHelper.readS16(buf), min = -2500, max = 2500 },
                    max = { value = gr.mspHelper.readS16(buf), min = -2500, max = 2500 },
                }
            end
            callback(callbackParam, inputs)
        end,
    }
    gr.mspQueue:add(message)
end

local function setMixerInput(index, input)
    local message = {
        command = 171, -- MSP_SET_MIXER_INPUT
        payload = { index }
    }
    gr.mspHelper.writeU16(message.payload, input.rate.value)
    gr.mspHelper.writeU16(message.payload, input.min.value)
    gr.mspHelper.writeU16(message.payload, input.max.value)
    gr.mspQueue:add(message)
end

-- The 32-slot mixer rule table. There is no bulk "set all" or single "get one rule"
-- command on the firmware -- rules are always fetched in bulk and written back one at a
-- time by index.

local function getMixerRules(callback, callbackParam)
    local message = {
        command = 172, -- MSP_MIXER_RULES
        processReply = function(self, buf)
            local rules = {}
            for i = 0, MIXER_RULE_COUNT - 1 do
                rules[i] = {
                    oper = { value = gr.mspHelper.readU8(buf), min = 0, max = 3, table = { [0] = "None", "Set", "Add", "Mul" } },
                    input = { value = gr.mspHelper.readU8(buf), min = 0, max = MIXER_INPUT_COUNT - 1 },
                    output = { value = gr.mspHelper.readU8(buf), min = 0, max = MIXER_OUTPUT_COUNT - 1, table = outputNames },
                    offset = { value = gr.mspHelper.readS16(buf), min = -2500, max = 2500 },
                    weight = { value = gr.mspHelper.readS16(buf), min = -10000, max = 10000 },
                    weightNeg = { value = gr.mspHelper.readS16(buf), min = -10000, max = 10000 },
                    speed = { value = gr.mspHelper.readU16(buf), min = 0, max = 60000 },
                    curve = { value = gr.mspHelper.readU8(buf), min = 0, max = MIXER_CURVE_COUNT },
                    condition = { value = gr.mspHelper.readU8(buf), min = 0, max = 16 },
                    role = { value = (buf.offset or 1) <= #buf and gr.mspHelper.readU8(buf) or 0, min = 0, max = 2 },
                }
            end
            callback(callbackParam, rules)
        end,
    }
    gr.mspQueue:add(message)
end

local function setMixerRule(index, rule)
    local message = {
        command = 173, -- MSP_SET_MIXER_RULE
        payload = { index }
    }
    gr.mspHelper.writeU8(message.payload, rule.oper.value)
    gr.mspHelper.writeU8(message.payload, rule.input.value)
    gr.mspHelper.writeU8(message.payload, rule.output.value)
    gr.mspHelper.writeU16(message.payload, rule.offset.value)
    gr.mspHelper.writeU16(message.payload, rule.weight.value)
    gr.mspHelper.writeU16(message.payload, rule.weightNeg.value)
    gr.mspHelper.writeU16(message.payload, rule.speed.value)
    gr.mspHelper.writeU8(message.payload, rule.curve.value)
    gr.mspHelper.writeU8(message.payload, rule.condition.value)
    gr.mspHelper.writeU8(message.payload, rule.role.value or 0)
    gr.mspQueue:add(message)
end

-- 8 curve slots a mixer rule's `curve` field can reference, each up to MIXER_CURVE_POINTS
-- (x,y) points. Firmware always sends/expects all MIXER_CURVE_POINTS slots regardless of
-- `count` (the extra points are simply unused), and rejects count outside [2, MIXER_CURVE_POINTS].

local function getMixerCurves(callback, callbackParam)
    local message = {
        command = 177, -- MSP_MIXER_CURVES
        processReply = function(self, buf)
            local curves = {}
            for i = 0, MIXER_CURVE_COUNT - 1 do
                local curve = { count = gr.mspHelper.readU8(buf), points = {} }
                for p = 0, MIXER_CURVE_POINTS - 1 do
                    curve.points[p] = {
                        x = gr.mspHelper.readS16(buf),
                        y = gr.mspHelper.readS16(buf),
                    }
                end
                curves[i] = curve
            end
            callback(callbackParam, curves)
        end,
    }
    gr.mspQueue:add(message)
end

local function setMixerCurve(index, curve)
    local message = {
        command = 178, -- MSP_SET_MIXER_CURVE
        payload = { index }
    }
    gr.mspHelper.writeU8(message.payload, curve.count)
    for p = 0, MIXER_CURVE_POINTS - 1 do
        local point = curve.points[p] or { x = 0, y = 0 }
        gr.mspHelper.writeU16(message.payload, point.x)
        gr.mspHelper.writeU16(message.payload, point.y)
    end
    gr.mspQueue:add(message)
end

-- Per mixer-INPUT override (not per-servo). Sentinel values below match firmware's
-- MIXER_OVERRIDE_OFF/MIXER_OVERRIDE_PASSTHROUGH exactly; valid index range is
-- 0..MIXER_INPUT_COUNT-1 (26 stabilized-axis/RC inputs), not a fixed heli servo count.

local function disableMixerOverride(mixerIndex)
    local message = {
        command = 191, -- MSP_SET_MIXER_OVERRIDE
        payload = { mixerIndex }
    }
    gr.mspHelper.writeU16(message.payload, 2501) -- MIXER_OVERRIDE_OFF
    gr.mspQueue:add(message)
end

local function enableMixerOverride(mixerIndex)
    local message = {
        command = 191, -- MSP_SET_MIXER_OVERRIDE
        payload = { mixerIndex }
    }
    gr.mspHelper.writeU16(message.payload, 2502) -- MIXER_OVERRIDE_PASSTHROUGH
    gr.mspQueue:add(message)
end

return {
    read = getMixerConfig,
    write = setMixerConfig,
    getDefaults = getDefaults,
    getMixerInputs = getMixerInputs,
    setMixerInput = setMixerInput,
    getMixerRules = getMixerRules,
    setMixerRule = setMixerRule,
    setServoNames = setServoNames,
    getMixerCurves = getMixerCurves,
    setMixerCurve = setMixerCurve,
    disableOverride = disableMixerOverride,
    enableOverride = enableMixerOverride,
    MIXER_INPUT_COUNT = MIXER_INPUT_COUNT,
    MIXER_OUTPUT_RESERVED_FIRST = MIXER_OUTPUT_RESERVED_FIRST,
    MIXER_OUTPUT_RESERVED_LAST = MIXER_OUTPUT_RESERVED_LAST,
    MIXER_RULE_COUNT = MIXER_RULE_COUNT,
    MIXER_CURVE_COUNT = MIXER_CURVE_COUNT,
    MIXER_CURVE_POINTS = MIXER_CURVE_POINTS,
}
