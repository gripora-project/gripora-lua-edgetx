local template = gr.executeScript(gr.radio.template)
local margin = template.margin
local lineSpacing = template.lineSpacing
local tableSpacing = template.tableSpacing
local sp = template.listSpacing.field
template = nil
local yMinLim = gr.radio.yMinLimit
local x = margin
local y = yMinLim - tableSpacing.header
local function incY(val) y = y + val return y end
local labels = {}
local fields = {}
local profileSwitcher = gr.executeScript("PAGES/helpers/profileSwitcher.lua")
local config = gr.useApi("mspDriveAids").getDefaults()
collectgarbage()

-- The firmware keeps these per PID profile and reads/writes the current one,
-- so the page has the profile switcher of the other profile pages.
fields[#fields + 1] = { t = "Current PID profile", x = x, y = incY(lineSpacing), sp = x + sp * 1.17, data = { value = nil, min = 0, max = 5, table = { [0] = "1", "2", "3", "4", "5", "6" } }, preEdit = profileSwitcher.startPidEditing, postEdit = profileSwitcher.endPidEditing }

-- Labels are kept short for 128 px screens. "Dyn" fields only act in the
-- Dynamic mode; the corner fields add to the rate and hold with steering lock.
fields[#fields + 1] = { t = "Mode",         x = x, y = incY(lineSpacing), sp = x + sp, data = config.abs_mode }
fields[#fields + 1] = { t = "Trigger",      x = x, y = incY(lineSpacing), sp = x + sp, data = config.abs_trigger }
fields[#fields + 1] = { t = "Rate",         x = x, y = incY(lineSpacing), sp = x + sp, data = config.abs_freq }
fields[#fields + 1] = { t = "Floor",        x = x, y = incY(lineSpacing), sp = x + sp, data = config.abs_floor }
fields[#fields + 1] = { t = "Hold",         x = x, y = incY(lineSpacing), sp = x + sp, data = config.abs_hold }
fields[#fields + 1] = { t = "Dyn rate",     x = x, y = incY(lineSpacing), sp = x + sp, data = config.abs_dyn_freq }
fields[#fields + 1] = { t = "Dyn hold",     x = x, y = incY(lineSpacing), sp = x + sp, data = config.abs_dyn_hold }
fields[#fields + 1] = { t = "Corner rate",  x = x, y = incY(lineSpacing), sp = x + sp, data = config.abs_corner_freq }
fields[#fields + 1] = { t = "Corner hold",  x = x, y = incY(lineSpacing), sp = x + sp, data = config.abs_corner_hold }

local function received(page, _)
    gr.onPageReady(page)
end

-- Firmware without drive aids answers with an MSP error: the ABS fields stay
-- "---" and the page cannot be saved. The profile switcher keeps working.
local function unsupported(page)
    for i = 2, #fields do
        fields[i].readOnly = true
    end
    page.readOnly = true
    gr.onPageReady(page)
end

return {
    read = function(self)
        self.profileSwitcher.getStatus(self)
        gr.useApi("mspDriveAids").read(received, self, config, unsupported)
    end,
    write = function(self)
        if config.abs_mode.value then
            gr.useApi("mspDriveAids").write(config)
            gr.settingsSaved(true, false)
        end
    end,
    title       = "ABS",
    labels      = labels,
    fields      = fields,
    profileSwitcher = profileSwitcher,

    timer = function(self)
        self.profileSwitcher.checkStatus(self)
    end,
}
