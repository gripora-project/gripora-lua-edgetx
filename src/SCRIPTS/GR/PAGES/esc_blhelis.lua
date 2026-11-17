local escParameters = nil
local escCount = 0
local selectedEsc = 0

local function clearForm(page)
    page.labels = {}
    page.fields = {}
    collectgarbage()
end

local receivedEscParameters -- forward declaration needed

local endEscEditing = function(field, page)
    selectedEsc = field.data.value
    clearForm(page)
    gr.useApi("mspEsc4wif").selectEsc(selectedEsc)
    gr.useApi("mspEscBlheliS").read(receivedEscParameters, page)
end

receivedEscParameters = function(page, data)
    escParameters = data
    clearForm(page)
    page.labels, page.fields = gr.executeScript("PAGES/esc_blhelis_form", escParameters, escCount, selectedEsc, endEscEditing)
    page.readOnly = false
    gr.onPageReady(page)
end

local function onProcessedMspStatus(page, status)
    escCount = status.motorCount
end

local page = {
    read = function(self)
        if not self.isReady then gr.onPageReady(self) end
        gr.useApi("mspEsc4wif").selectEsc(selectedEsc, 2)
        gr.useApi("mspStatus").getStatus(onProcessedMspStatus, self)
        gr.useApi("mspEscBlheliS").read(receivedEscParameters, self)
    end,
    write = function(self)
        clearForm(self)
        gr.useApi("mspEscBlheliS").write(escParameters)
        gr.useApi("mspEscBlheliS").write(escParameters) -- sometimes writing once won't work, especially after clearEscSelection has been called.
        escParameters = nil
        gr.useApi("mspEscBlheliS").read(receivedEscParameters, self)
    end,
    unload = function(self)
        gr.useApi("mspEsc4wif").clearEscSelection()
    end,
    title       = "BLHeli_S",
    readOnly    = true
}

page.labels, page.fields = gr.executeScript("PAGES/esc_blhelis_form", nil)

return page