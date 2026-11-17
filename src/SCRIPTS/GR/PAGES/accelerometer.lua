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
local mspAccTrim = "mspAccTrim"
local data = gr.useApi(mspAccTrim).getDefaults()

labels[#labels + 1] = { t = "Accelerometer Trim", x = x,          y = incY(lineSpacing) }
fields[#fields + 1] = { t = "Roll",               x = x + indent, y = incY(lineSpacing), sp = x + sp, data = data.roll_trim }
fields[#fields + 1] = { t = "Pitch",              x = x + indent, y = incY(lineSpacing), sp = x + sp, data = data.pitch_trim }

local function receivedData(page)
    gr.onPageReady(page)
end

return {
    read = function(self)
        gr.useApi(mspAccTrim).read(receivedData, self, data)
    end,
    write = function(self)
        if data.roll_trim.value then
            gr.useApi(mspAccTrim).write(data)
            gr.settingsSaved(true, false)
        end
    end,
    title       = "Accelerometer",
    labels      = labels,
    fields      = fields
}
