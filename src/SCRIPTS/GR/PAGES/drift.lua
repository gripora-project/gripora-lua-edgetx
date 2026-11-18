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
local config = gr.useApi("mspDrift").getDefaults()
collectgarbage()

-- The firmware keeps these per PID profile and reads/writes the current one,
-- so the page has the profile switcher of the other profile pages.
fields[#fields + 1] = { t = "Current PID profile", x = x, y = incY(lineSpacing), sp = x + sp * 1.17, data = { value = nil, min = 0, max = 5, table = { [0] = "1", "2", "3", "4", "5", "6" } }, preEdit = profileSwitcher.startPidEditing, postEdit = profileSwitcher.endPidEditing }

-- In DRIFT the wheel steers directly and the gyro counter-steers against turn
-- rate beyond the allowed rate: 100 % gain is full lock 360 deg/s past it,
-- never more than the counter limit. Labels are kept short for 128 px screens.
labels[#labels + 1] = { t = "Drift",         x = x, y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Counter gain",  x = x, y = incY(lineSpacing), sp = x + sp, data = config.gain }
fields[#fields + 1] = { t = "Allowed rate",  x = x, y = incY(lineSpacing), sp = x + sp, data = config.allow }
fields[#fields + 1] = { t = "Counter limit", x = x, y = incY(lineSpacing), sp = x + sp, data = config.limit }

incY(lineSpacing * 0.5)
labels[#labels + 1] = { t = "The DRIFT mode", x = x, y = incY(lineSpacing), bold = false }
labels[#labels + 1] = { t = "switch turns it on.", x = x, y = incY(lineSpacing), bold = false }

local function received(page, _)
    gr.onPageReady(page)
end

-- Firmware without DRIFT answers with an MSP error: the fields stay "---" and
-- the page cannot be saved. The profile switcher keeps working.
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
        gr.useApi("mspDrift").read(received, self, config, unsupported)
    end,
    write = function(self)
        if config.gain.value then
            gr.useApi("mspDrift").write(config)
            gr.settingsSaved(true, false)
        end
    end,
    title       = "Drift",
    labels      = labels,
    fields      = fields,
    profileSwitcher = profileSwitcher,

    timer = function(self)
        self.profileSwitcher.checkStatus(self)
    end,
}
