local batSwitcher = {
    mspBatteryProfile = gr.executeScript("MSP/mspBatteryProfile"),
    editing = false,
    adjustmentTS = nil,

    getStatus = function(page, currentField)
        local self = page.batSwitcher
        self.currentField = currentField
        self.mspBatteryProfile.read(self.onProcessedBatteryProfile, page)
    end,

    checkStatus = function(page)
        local self = page.batSwitcher
        if self.adjustmentTS and gr.clock() - self.adjustmentTS > 0.5 then
            gr.reloadPage()
        elseif gr.mspQueue:isProcessed() and not self.editing then
            self.mspBatteryProfile.read(self.onProcessedBatteryProfile, page)
        end
    end,

    onProcessedBatteryProfile = function(page, status)
        local self = page.batSwitcher
        local currentField = self.currentField
        if currentField.data.value ~= status.batteryProfile.value and not page.batSwitcher.editing then
            if currentField.data.value then
                page.batSwitcher.adjustmentTS = gr.clock()
            end
            currentField.data.value = status.batteryProfile.value
            gr.lcdNeedsInvalidate = true
        end

        page.isReady = true
    end,

    startEditing = function(field, page)
        local self = page.batSwitcher
        self.editing = true
    end,

    endEditing = function(field, page)
        local self = page.batSwitcher
        local status = { batteryProfile = field.data }
        self.mspBatteryProfile.write(status, function() gr.reloadPage() end, nil)
    end
}

return batSwitcher