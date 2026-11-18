local template = gr.executeScript(gr.radio.template)
local mspStatus = gr.useApi("mspStatus")
local margin = template.margin
local indent = template.indent
local lineSpacing = template.lineSpacing
local tableSpacing = template.tableSpacing
local colSpacing = tableSpacing.col * 0.65
local sp = template.listSpacing.field
template = nil
local yMinLim = gr.radio.yMinLimit
local x = margin
local y = yMinLim - lineSpacing
local function incY(val) y = y + val return y end
local labels = {}
local fields = {}
local editing = false
local profileAdjustmentTS = nil
local pids = gr.useApi("mspPidTuning").getDefaults()
collectgarbage()

local startEditing = function(field, page)
    editing = true
end

local endPidEditing = function(field, page)
    gr.useApi("mspSetProfile").setPidProfile(field.data.value, function() gr.reloadPage() end, nil)
end

local function copyProfile(field, page)
    local source = page.fields[16].data.value
    local dest = page.fields[17].data.value
    if source == dest then return end

    local mspCopyProfile = {
        command = 183, -- MSP_COPY_PROFILE
        payload = { 0, dest, source } -- 0 = copy pids
    }

    gr.mspQueue:add(mspCopyProfile)
    gr.settingsSaved(true, false)
end

x = margin
local tableStartY = yMinLim - lineSpacing
y = tableStartY
labels[#labels + 1] = { t = "",      x = x, y = incY(tableSpacing.header) }
labels[#labels + 1] = { t = "Roll",  x = x, y = incY(tableSpacing.row) }
labels[#labels + 1] = { t = "Pitch", x = x, y = incY(tableSpacing.row) }
labels[#labels + 1] = { t = "Steer", x = x, y = incY(tableSpacing.row) }

x = x + tableSpacing.col
y = tableStartY
labels[#labels + 1] = { t = "P",     x = x, y = incY(tableSpacing.header) }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.roll_p }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.pitch_p }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.yaw_p }

x = x + colSpacing
y = tableStartY
labels[#labels + 1] = { t = "I",     x = x, y = incY(tableSpacing.header) }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.roll_i }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.pitch_i }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.yaw_i }

x = x + colSpacing
y = tableStartY
labels[#labels + 1] = { t = "D",     x = x, y = incY(tableSpacing.header) }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.roll_d }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.pitch_d }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.yaw_d }

x = x + colSpacing
y = tableStartY
labels[#labels + 1] = { t = "FF",    x = x, y = incY(tableSpacing.header) }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.roll_f }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.pitch_f }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.yaw_f }

x = x + colSpacing
y = tableStartY
labels[#labels + 1] = { t = "B",     x = x, y = incY(tableSpacing.header) }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.roll_b }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.pitch_b }
fields[#fields + 1] = {              x = x, y = incY(tableSpacing.row), w = 50, data = pids.yaw_b }

x = margin
incY(lineSpacing * 0.5)
fields[16] = { t = "Current PID profile",             x = x,          y = incY(lineSpacing), sp = x + sp * 1.17, data = { value = nil, min = 0, max = 5, table = { [0] = "1", "2", "3", "4", "5", "6" } }, preEdit = startEditing, postEdit = endPidEditing }
fields[17] = { t = "Destination profile",             x = x,          y = incY(lineSpacing), sp = x + sp * 1.17, data = { value = nil, min = 0, max = 5, table = { [0] = "1", "2", "3", "4", "5", "6" } } }
fields[#fields + 1] = { t = "[Copy Current to Dest]", x = x + indent, y = incY(lineSpacing), preEdit = copyProfile }

local function receivedPidTuning(page, data)
    gr.onPageReady(page)
end

return {
    read = function(self)
        mspStatus.getStatus(self.onProcessedMspStatus, self)
        gr.useApi("mspPidTuning").read(receivedPidTuning, self, pids)
    end,
    write = function(self)
        if pids.roll_p.value then
            gr.useApi("mspPidTuning").write(pids)
            gr.settingsSaved(true, false)
        end
    end,
    title       = "PID Gains",
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
        local currentField = self.fields[16]
        if currentField.data.value ~= status.profile and not editing then
            if currentField.data.value then
                profileAdjustmentTS = gr.clock()
            end
            currentField.data.value = status.profile
        end

        local destField = self.fields[17]
        if not destField.data.value then
            if status.profile < 5 then
                destField.data.value = status.profile + 1
            else
                destField.data.value = 4
            end
        end

        gr.lcdNeedsInvalidate = true
        self.isReady = true
    end,
}
