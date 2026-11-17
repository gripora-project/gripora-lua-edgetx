--gr.showMemoryUsage(">>>>> PAGE LOAD <<<<<<")
local template = gr.executeScript(gr.radio.template)
--gr.showMemoryUsage("after template")
local mspStatus = gr.useApi("mspStatus")
--gr.showMemoryUsage("after mspStatus")
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
local rcTuning = gr.useApi("mspRcTuning").getDefaults()
--gr.showMemoryUsage("after getDefaults")
collectgarbage()
local editing = false
local profileAdjustmentTS = nil

local startEditing = function(field, page)
    editing = true
end

local endRateEditing = function(field, page)
    gr.useApi("mspSetProfile").setRateProfile(field.data.value, function() gr.reloadPage() end, nil)
end

local function copyProfile(field, page)
    local source = page.fields[13].data.value
    local dest = page.fields[14].data.value
    if source == dest then return end

    local mspCopyProfile = {
        command = 183, -- MSP_COPY_PROFILE
        payload = { 1, dest, source } -- 1 = copy rates
    }

    gr.mspQueue:add(mspCopyProfile)
    gr.settingsSaved(true, false)
end

local function buildForm()
    --gr.showMemoryUsage("before buildform")
    local tableStartY = yMinLim - lineSpacing
    y = tableStartY
    labels = {}
    fields = {}

    labels[#labels + 1] = { t = "",      x = x, y = incY(tableSpacing.header) }
    labels[#labels + 1] = { t = "",      x = x, y = incY(tableSpacing.header) }
    labels[#labels + 1] = { t = "Roll",  x = x, y = incY(tableSpacing.row) }
    labels[#labels + 1] = { t = "Pitch", x = x, y = incY(tableSpacing.row) }
    labels[#labels + 1] = { t = "Yaw",   x = x, y = incY(tableSpacing.row) }

    x = x + tableSpacing.col
    y = tableStartY
    labels[#labels + 1] = { t = rcTuning.columnHeaders[1], x = x, y = incY(tableSpacing.header) }
    labels[#labels + 1] = { t = rcTuning.columnHeaders[2], x = x, y = incY(tableSpacing.header) }
    fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), data = rcTuning.roll_rcRates }
    fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), data = rcTuning.pitch_rcRates }
    fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), data = rcTuning.yaw_rcRates }

    x = x + tableSpacing.col
    y = tableStartY
    labels[#labels + 1] = { t = rcTuning.columnHeaders[3], x = x, y = incY(tableSpacing.header) }
    labels[#labels + 1] = { t = rcTuning.columnHeaders[4], x = x, y = incY(tableSpacing.header) }
    fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), data = rcTuning.roll_rates }
    fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), data = rcTuning.pitch_rates }
    fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), data = rcTuning.yaw_rates }

    x = x + tableSpacing.col
    y = tableStartY
    labels[#labels + 1] = { t = rcTuning.columnHeaders[5], x = x, y = incY(tableSpacing.header) }
    labels[#labels + 1] = { t = rcTuning.columnHeaders[6], x = x, y = incY(tableSpacing.header) }
    fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), data = rcTuning.roll_rcExpo }
    fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), data = rcTuning.pitch_rcExpo }
    fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), data = rcTuning.yaw_rcExpo }

    x = margin
    incY(lineSpacing * 0.5)
    fields[13] = { t = "Current rate profile",            x = x,          y = incY(lineSpacing), sp = x + sp * 1.17, data = { min = 0, max = 5, value = rcTuning.currentRateProfile, table = { [0] = "1", "2", "3", "4", "5", "6" } }, preEdit = startEditing, postEdit = endRateEditing }
    fields[14] = { t = "Destination profile",             x = x,          y = incY(lineSpacing), sp = x + sp * 1.17, data = { min = 0, max = 5, value = rcTuning.destRateProfile, table = { [0] = "1", "2", "3", "4", "5", "6" } } }
    fields[#fields + 1] = { t = "[Copy Current to Dest]", x = x + indent, y = incY(lineSpacing), preEdit = copyProfile }
    --gr.showMemoryUsage("after buildform")
end

buildForm()

local function rebuildForm(page)
    labels = nil
    fields = nil
    page.labels = nil
    page.fields = nil
    collectgarbage()
    buildForm()
    page.labels = labels
    page.fields = fields
end

local function receivedRcTuning(page)
    rebuildForm(page)
    gr.onPageReady(page)
end

return {
    read = function(self)
        mspStatus.getStatus(self.onProcessedMspStatus, self)
        gr.useApi("mspRcTuning").read(receivedRcTuning, self, rcTuning)
    end,
    write = function(self)
        if rcTuning.roll_rcRates.value then
            gr.useApi("mspRcTuning").write(rcTuning)
            gr.settingsSaved(true, false)
        end
    end,
    title       = "Rates",
    labels      = labels,
    fields      = fields,

    timer = function(self)
        if profileAdjustmentTS and gr.clock() - profileAdjustmentTS > 0.35 then
            gr.reloadPage()
        elseif gr.mspQueue:isProcessed() and not editing then
            mspStatus.getStatus(self.onProcessedMspStatus, self)
        end
    end,

    onProcessedMspStatus = function(self, status)
        local currentField = self.fields[13]
        if currentField.data.value ~= status.rateProfile and not editing then
            if currentField.data.value then
                profileAdjustmentTS = gr.clock()
            end
            currentField.data.value = status.rateProfile
            rcTuning.currentRateProfile = status.rateProfile
        end
        local destField = self.fields[14]
        if not destField.data.value then
            if status.rateProfile < 5 then
                destField.data.value = status.rateProfile + 1
            else
                destField.data.value = 4
            end
            rcTuning.destRateProfile = destField.data.value
        end
        gr.lcdNeedsInvalidate = true
        self.isReady = true
    end,
}
