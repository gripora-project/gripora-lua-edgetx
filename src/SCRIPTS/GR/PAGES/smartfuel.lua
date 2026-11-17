local template = gr.executeScript(gr.radio.template)
local margin = template.margin
local indent = template.indent
local lineSpacing = template.lineSpacing
local tableSpacing = template.tableSpacing
local sp = template.listSpacing.field
local yMinLim = gr.radio.yMinLimit
local x = margin
local y = yMinLim - lineSpacing
local function incY(val) y = y + val return y end
local labels = {}
local fields = {}
local smartFuelConfig = gr.useApi("mspSmartFuel").getDefaults()

x = margin
y = yMinLim - tableSpacing.header

fields[#fields + 1] = { t = "Mode",                     x = x, y = incY(lineSpacing), sp = x + sp, w = 110, data = smartFuelConfig.smartfuel_mode }
fields[#fields + 1] = { t = "Voltage Drop Rate",        x = x, y = incY(lineSpacing), sp = x + sp, w = 110, data = smartFuelConfig.smartfuel_voltage_drop_rate }
fields[#fields + 1] = { t = "Charge Drop Rate",         x = x, y = incY(lineSpacing), sp = x + sp, w = 110, data = smartFuelConfig.smartfuel_charge_drop_rate }
fields[#fields + 1] = { t = "Sag Gain",                 x = x, y = incY(lineSpacing), sp = x + sp, w = 110, data = smartFuelConfig.smartfuel_sag_gain }

local function receivedSmartFuelConfig(page, _)
    gr.onPageReady(page)
end

return {
    read = function(self)
        gr.useApi("mspSmartFuel").read(receivedSmartFuelConfig, self, smartFuelConfig)
    end,
    write = function(self)
        if smartFuelConfig.smartfuel_mode.value then
            gr.useApi("mspSmartFuel").write(smartFuelConfig)
            gr.settingsSaved(true, false)
        end
    end,
    title       = "Smart Fuel",
    labels      = labels,
    fields      = fields
}
