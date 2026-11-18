local template = gr.executeScript(gr.radio.template)
local margin = template.margin
local indent = template.indent
local lineSpacing = template.lineSpacing
local tableSpacing = template.tableSpacing
local sp = template.listSpacing.field
template = nil
local yMinLim = gr.radio.yMinLimit
local x = margin
local y = yMinLim - lineSpacing
local function incY(val) y = y + val return y end
local labels = {}
local fields = {}
local profileSwitcher = gr.executeScript("PAGES/helpers/profileSwitcher.lua")
local pidProfile = gr.useApi("mspPidProfile").getDefaults()
collectgarbage()

fields[#fields + 1] = { t = "Current PID profile",     x = x,          y = incY(lineSpacing), sp = x + sp * 1.17, data = { value = nil, min = 0, max = 5, table = { [0] = "1", "2", "3", "4", "5", "6" } }, preEdit = profileSwitcher.startPidEditing, postEdit = profileSwitcher.endPidEditing }

-- Build once after the reply so old firmware only shows supported fields.
local function buildProfileFields()
    for i = #fields, 2, -1 do fields[i] = nil end
    for i = #labels, 1, -1 do labels[i] = nil end
    y = fields[1].y
    incY(lineSpacing * 0.25)
    labels[#labels + 1] = { t = "Throttle",                x = x,          y = incY(lineSpacing) }
    fields[#fields + 1] = { t = "Gain",                    x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.fw_tpa_gain }
    if pidProfile.has_fw_spa then
        -- GPS speed attenuation: needs a GPS fix and a Speed curve below
        labels[#labels + 1] = { t = "GPS Speed",           x = x,          y = incY(lineSpacing) }
        fields[#fields + 1] = { t = "Gain",                x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.fw_spa_gain }
    end

    incY(lineSpacing * 0.25)
    labels[#labels + 1] = { t = "Driving Feel",              x = x,          y = incY(lineSpacing) }
    labels[#labels + 1] = { t = "Master Gain",             x = x + indent, y = incY(lineSpacing), bold = false }
    fields[#fields + 1] = { t = "Roll (unused)",           x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.master_gain_roll }
    fields[#fields + 1] = { t = "Pitch (unused)",          x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.master_gain_pitch }
    fields[#fields + 1] = { t = "Steering",                x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.master_gain_yaw }
    labels[#labels + 1] = { t = "I-term Decay",            x = x + indent, y = incY(lineSpacing), bold = false }
    fields[#fields + 1] = { t = "Roll (unused)",           x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.iterm_decay_time_roll }
    fields[#fields + 1] = { t = "Pitch (unused)",          x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.iterm_decay_time_pitch }
    fields[#fields + 1] = { t = "Steering",                x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.iterm_decay_time_yaw }
    labels[#labels + 1] = { t = "I-term Relax",            x = x + indent, y = incY(lineSpacing), bold = false }
    fields[#fields + 1] = { t = "Roll (unused)",           x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.bounceback_roll }
    fields[#fields + 1] = { t = "Pitch (unused)",          x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.bounceback_pitch }
    fields[#fields + 1] = { t = "Steering",                x = x + indent*2, y = incY(lineSpacing), sp = x + sp, data = pidProfile.bounceback_yaw }

    -- Gain curves (advanced shaping), kept apart from Driving Feel
    incY(lineSpacing * 0.25)
    labels[#labels + 1] = { t = "Gain Curves",             x = x,          y = incY(lineSpacing) }
    fields[#fields + 1] = { t = "Roll (unused)",           x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.gain_curve_roll }
    fields[#fields + 1] = { t = "Pitch (unused)",          x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.gain_curve_pitch }
    fields[#fields + 1] = { t = "Steering",                x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.gain_curve_yaw }
    fields[#fields + 1] = { t = "Throttle",                x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.fw_tpa_curve }
    if pidProfile.has_fw_spa then
        fields[#fields + 1] = { t = "Speed",               x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.fw_spa_curve }
        fields[#fields + 1] = { t = "Speed range",         x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.fw_spa_speed_max }
    end
end

local function receivedPidProfile(page, _)
    buildProfileFields()
    gr.onPageReady(page)
end

return {
    read = function(self)
        self.profileSwitcher.getStatus(self)
        gr.useApi("mspPidProfile").read(receivedPidProfile, self, pidProfile)
    end,
    write = function(self)
        if pidProfile.fw_tpa_gain.value then
            gr.useApi("mspPidProfile").write(pidProfile)
            gr.settingsSaved(true, false)
        end
    end,
    title       = "Profile - Various",
    labels      = labels,
    fields      = fields,
    profileSwitcher = profileSwitcher,

    timer = function(self)
        self.profileSwitcher.checkStatus(self)
    end,
}
