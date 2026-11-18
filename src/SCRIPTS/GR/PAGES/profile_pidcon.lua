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

incY(lineSpacing * 0.25)
labels[#labels + 1] = { t = "I-term Relax Level",      x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Roll (unused)",           x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.iterm_relax_level_roll }
fields[#fields + 1] = { t = "Pitch (unused)",          x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.iterm_relax_level_pitch }
fields[#fields + 1] = { t = "Steering",                x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.iterm_relax_level_yaw }
labels[#labels + 1] = { t = "I-term Decay",            x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Limit",                   x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.iterm_decay_limit }
labels[#labels + 1] = { t = "Error Limit",             x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Roll (unused)",           x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.error_limit_roll }
fields[#fields + 1] = { t = "Pitch (unused)",          x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.error_limit_pitch }
fields[#fields + 1] = { t = "Steering",                x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.error_limit_yaw }

incY(lineSpacing * 0.25)
labels[#labels + 1] = { t = "PID Controller",          x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "R bandwidth",             x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.gyro_cutoff_roll }
fields[#fields + 1] = { t = "P bandwidth",             x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.gyro_cutoff_pitch }
fields[#fields + 1] = { t = "Steer bandwidth",         x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.gyro_cutoff_yaw }
fields[#fields + 1] = { t = "R D-term cutoff",         x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.dterm_cutoff_roll }
fields[#fields + 1] = { t = "P D-term cutoff",         x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.dterm_cutoff_pitch }
fields[#fields + 1] = { t = "Steer D cutoff",          x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.dterm_cutoff_yaw }
fields[#fields + 1] = { t = "R B-term cutoff",         x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.bterm_cutoff_roll }
fields[#fields + 1] = { t = "P B-term cutoff",         x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.bterm_cutoff_pitch }
fields[#fields + 1] = { t = "Steer B cutoff",          x = x + indent, y = incY(lineSpacing), sp = x + sp, data = pidProfile.bterm_cutoff_yaw }

local function receivedPidProfile(page, _)
    gr.onPageReady(page)
end

return {
    read = function(self)
        self.profileSwitcher.getStatus(self)
        gr.useApi("mspPidProfile").read(receivedPidProfile, self, pidProfile)
    end,
    write = function(self)
        if pidProfile.iterm_relax_level_roll.value then
            gr.useApi("mspPidProfile").write(pidProfile)
            gr.settingsSaved(true, false)
        end
    end,
    title       = "PID Controller Settings",
    labels      = labels,
    fields      = fields,
    profileSwitcher = profileSwitcher,

    timer = function(self)
        self.profileSwitcher.checkStatus(self)
    end,
}
