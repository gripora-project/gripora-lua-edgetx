-- MSP_PID_PROFILE / MSP_SET_PID_PROFILE: verified against Gripora msp.c.
-- 51-byte base, then 1 + 4 + 4 reserved bytes, API 22.10 GPS speed attenuation (4),
-- then 1 + 6 + 4 reserved bytes (75 in all). The reserved bytes held Angle mode, Trainer,
-- Attitude Hold, Auto Hover, Cross-Axis Relax, Snap Relax and Prop Hang settings, which
-- the firmware no longer has; they are read and written back unchanged. Only the length
-- received from the FC is written.

local function getDefaults()
    local data = {}
    data.pid_mode = { min = 0, max = 250 }
    data.iterm_decay_time_roll = { min = 1, max = 100, scale = 100, unit = gr.units.seconds }
    data.iterm_decay_time_pitch = { min = 1, max = 100, scale = 100, unit = gr.units.seconds }
    data.iterm_decay_time_yaw = { min = 1, max = 100, scale = 100, unit = gr.units.seconds }
    data.iterm_decay_limit = { min = 0, max = 250, unit = gr.units.degreesPerSecond }
    data.error_limit_roll = { min = 0, max = 180, unit = gr.units.degrees }
    data.error_limit_pitch = { min = 0, max = 180, unit = gr.units.degrees }
    data.error_limit_yaw = { min = 0, max = 180, unit = gr.units.degrees }
    data.gyro_cutoff_roll = { min = 0, max = 250, unit = gr.units.herz }
    data.gyro_cutoff_pitch = { min = 0, max = 250, unit = gr.units.herz }
    data.gyro_cutoff_yaw = { min = 0, max = 250, unit = gr.units.herz }
    data.dterm_cutoff_roll = { min = 0, max = 250, unit = gr.units.herz }
    data.dterm_cutoff_pitch = { min = 0, max = 250, unit = gr.units.herz }
    data.dterm_cutoff_yaw = { min = 0, max = 250, unit = gr.units.herz }
    data.iterm_relax_level_roll = { min = 10, max = 250, unit = gr.units.degreesPerSecond }
    data.iterm_relax_level_pitch = { min = 10, max = 250, unit = gr.units.degreesPerSecond }
    data.iterm_relax_level_yaw = { min = 10, max = 250, unit = gr.units.degreesPerSecond }
    data.bounceback_roll = { min = 1, max = 10 }
    data.bounceback_pitch = { min = 1, max = 10 }
    data.bounceback_yaw = { min = 1, max = 10 }
    data.bterm_cutoff_roll = { min = 0, max = 250, unit = gr.units.herz }
    data.bterm_cutoff_pitch = { min = 0, max = 250, unit = gr.units.herz }
    data.bterm_cutoff_yaw = { min = 0, max = 250, unit = gr.units.herz }
    data.fw_tpa_gain = { min = 25, max = 200, unit = gr.units.percentage }
    data.fw_tpa_curve = { min = 0, max = 8 }
    data.master_gain_roll = { min = 0, max = 200, unit = gr.units.percentage }
    data.master_gain_pitch = { min = 0, max = 200, unit = gr.units.percentage }
    data.master_gain_yaw = { min = 0, max = 200, unit = gr.units.percentage }
    data.gain_curve_roll = { min = 0, max = 8 }
    data.gain_curve_pitch = { min = 0, max = 8 }
    data.gain_curve_yaw = { min = 0, max = 8 }
    data.fw_spa_gain = { min = 25, max = 200, unit = gr.units.percentage }
    data.fw_spa_curve = { min = 0, max = 8 }
    data.fw_spa_speed_max = { min = 10, max = 300, unit = "km/h" }
    return data
end

local function getPidProfile(callback, callbackParam, data)
    data = data or getDefaults()
    local message = {
        command = 94, -- MSP_PID_PROFILE
        processReply = function(self, buf)
            local reserved = {}
            local function skip(n)
                for _ = 1, n do reserved[#reserved + 1] = gr.mspHelper.readU8(buf) end
            end
            data.reserved = reserved
            data.length = #buf
            data.pid_mode.value = gr.mspHelper.readU8(buf)
            data.iterm_decay_time_roll.value = gr.mspHelper.readU8(buf)
            data.iterm_decay_time_pitch.value = gr.mspHelper.readU8(buf)
            data.iterm_decay_time_yaw.value = gr.mspHelper.readU8(buf)
            data.iterm_decay_limit.value = gr.mspHelper.readU8(buf)
            data.error_limit_roll.value = gr.mspHelper.readU8(buf)
            data.error_limit_pitch.value = gr.mspHelper.readU8(buf)
            data.error_limit_yaw.value = gr.mspHelper.readU8(buf)
            data.gyro_cutoff_roll.value = gr.mspHelper.readU8(buf)
            data.gyro_cutoff_pitch.value = gr.mspHelper.readU8(buf)
            data.gyro_cutoff_yaw.value = gr.mspHelper.readU8(buf)
            data.dterm_cutoff_roll.value = gr.mspHelper.readU8(buf)
            data.dterm_cutoff_pitch.value = gr.mspHelper.readU8(buf)
            data.dterm_cutoff_yaw.value = gr.mspHelper.readU8(buf)
            data.iterm_relax_level_roll.value = gr.mspHelper.readU8(buf)
            data.iterm_relax_level_pitch.value = gr.mspHelper.readU8(buf)
            data.iterm_relax_level_yaw.value = gr.mspHelper.readU8(buf)
            data.bounceback_roll.value = gr.mspHelper.readU8(buf)
            data.bounceback_pitch.value = gr.mspHelper.readU8(buf)
            data.bounceback_yaw.value = gr.mspHelper.readU8(buf)
            skip(7) -- was Angle mode strength/limit, Horizon, Trainer gain/limit, Attitude Hold gain/deadband
            data.bterm_cutoff_roll.value = gr.mspHelper.readU8(buf)
            data.bterm_cutoff_pitch.value = gr.mspHelper.readU8(buf)
            data.bterm_cutoff_yaw.value = gr.mspHelper.readU8(buf)
            data.fw_tpa_gain.value = gr.mspHelper.readU8(buf)
            data.fw_tpa_curve.value = gr.mspHelper.readU8(buf)
            data.master_gain_roll.value = gr.mspHelper.readU16(buf)
            data.master_gain_pitch.value = gr.mspHelper.readU16(buf)
            data.master_gain_yaw.value = gr.mspHelper.readU16(buf)
            skip(8) -- was Auto Hover gain/angle/rate (4), Cross-Axis Relax (4)
            data.gain_curve_roll.value = gr.mspHelper.readU8(buf)
            data.gain_curve_pitch.value = gr.mspHelper.readU8(buf)
            data.gain_curve_yaw.value = gr.mspHelper.readU8(buf)
            skip(2) -- was Attitude Hold max rate
            -- was Auto Hover roll deadband (1), throttle assist (4), Angle/Trainer axis limits (4)
            if #buf >= 52 then skip(1) end
            if #buf >= 56 then skip(4) end
            if #buf >= 60 then skip(4) end
            data.has_fw_spa = #buf >= 64
            data.fw_spa_gain.value = nil
            data.fw_spa_curve.value = nil
            data.fw_spa_speed_max.value = nil
            if data.has_fw_spa then
                data.fw_spa_gain.value = gr.mspHelper.readU8(buf)
                data.fw_spa_curve.value = gr.mspHelper.readU8(buf)
                data.fw_spa_speed_max.value = gr.mspHelper.readU16(buf)
            end
            -- was Angle mode damping (1), Snap Relax (6), Prop Hang (4)
            if #buf >= 65 then skip(1) end
            if #buf >= 71 then skip(6) end
            if #buf >= 75 then skip(4) end
            callback(callbackParam, data)
        end,
        simulatorResponse = {
            1, 60, 60, 60, 35,              -- pid mode, I-term decay time, limit
            45, 45, 60,                     -- error limit
            50, 50, 100, 15, 15, 20,        -- gyro, D-term cutoffs
            22, 22, 22, 5, 5, 5,            -- I-term relax level, bounceback
            0, 0, 0, 0, 0, 0, 0,            -- reserved
            15, 15, 20, 100, 0,             -- B-term cutoffs, TPA gain, curve
            100, 0, 100, 0, 100, 0,         -- master gains
            0, 0, 0, 0, 0, 0, 0, 0,         -- reserved
            0, 0, 0,                        -- gain curves
            0, 0, 0, 0, 0, 0, 0,            -- reserved
            0, 0, 0, 0,                     -- reserved
            100, 0, 150, 0,                 -- SPA gain, curve, speed max
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 -- reserved
        },
    }
    gr.mspQueue:add(message)
end

local function setPidProfile(data)
    local message = {
        command = 95, -- MSP_SET_PID_PROFILE
        payload = {},
        simulatorResponse = {}
    }
    local reserved, r = data.reserved or {}, 0
    local function keep(n)
        for _ = 1, n do
            r = r + 1
            gr.mspHelper.writeU8(message.payload, reserved[r] or 0)
        end
    end
    local length = data.length or 51
    gr.mspHelper.writeU8(message.payload, data.pid_mode.value)
    gr.mspHelper.writeU8(message.payload, data.iterm_decay_time_roll.value)
    gr.mspHelper.writeU8(message.payload, data.iterm_decay_time_pitch.value)
    gr.mspHelper.writeU8(message.payload, data.iterm_decay_time_yaw.value)
    gr.mspHelper.writeU8(message.payload, data.iterm_decay_limit.value)
    gr.mspHelper.writeU8(message.payload, data.error_limit_roll.value)
    gr.mspHelper.writeU8(message.payload, data.error_limit_pitch.value)
    gr.mspHelper.writeU8(message.payload, data.error_limit_yaw.value)
    gr.mspHelper.writeU8(message.payload, data.gyro_cutoff_roll.value)
    gr.mspHelper.writeU8(message.payload, data.gyro_cutoff_pitch.value)
    gr.mspHelper.writeU8(message.payload, data.gyro_cutoff_yaw.value)
    gr.mspHelper.writeU8(message.payload, data.dterm_cutoff_roll.value)
    gr.mspHelper.writeU8(message.payload, data.dterm_cutoff_pitch.value)
    gr.mspHelper.writeU8(message.payload, data.dterm_cutoff_yaw.value)
    gr.mspHelper.writeU8(message.payload, data.iterm_relax_level_roll.value)
    gr.mspHelper.writeU8(message.payload, data.iterm_relax_level_pitch.value)
    gr.mspHelper.writeU8(message.payload, data.iterm_relax_level_yaw.value)
    gr.mspHelper.writeU8(message.payload, data.bounceback_roll.value)
    gr.mspHelper.writeU8(message.payload, data.bounceback_pitch.value)
    gr.mspHelper.writeU8(message.payload, data.bounceback_yaw.value)
    keep(7)
    gr.mspHelper.writeU8(message.payload, data.bterm_cutoff_roll.value)
    gr.mspHelper.writeU8(message.payload, data.bterm_cutoff_pitch.value)
    gr.mspHelper.writeU8(message.payload, data.bterm_cutoff_yaw.value)
    gr.mspHelper.writeU8(message.payload, data.fw_tpa_gain.value)
    gr.mspHelper.writeU8(message.payload, data.fw_tpa_curve.value)
    gr.mspHelper.writeU16(message.payload, data.master_gain_roll.value)
    gr.mspHelper.writeU16(message.payload, data.master_gain_pitch.value)
    gr.mspHelper.writeU16(message.payload, data.master_gain_yaw.value)
    keep(8)
    gr.mspHelper.writeU8(message.payload, data.gain_curve_roll.value)
    gr.mspHelper.writeU8(message.payload, data.gain_curve_pitch.value)
    gr.mspHelper.writeU8(message.payload, data.gain_curve_yaw.value)
    keep(2)
    if length >= 52 then keep(1) end
    if length >= 56 then keep(4) end
    if length >= 60 then keep(4) end
    if length >= 64 then
        gr.mspHelper.writeU8(message.payload, data.fw_spa_gain.value)
        gr.mspHelper.writeU8(message.payload, data.fw_spa_curve.value)
        gr.mspHelper.writeU16(message.payload, data.fw_spa_speed_max.value)
    end
    if length >= 65 then keep(1) end
    if length >= 71 then keep(6) end
    if length >= 75 then keep(4) end
    gr.mspQueue:add(message)
end

return {
    read = getPidProfile,
    write = setPidProfile,
    getDefaults = getDefaults
}
