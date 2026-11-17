local function getDataflashSummary(callback, callbackParam)
    local message = {
        command = 70, -- MSP_DATAFLASH_SUMMARY
        processReply = function(self, buf)
            local summary = {}
            --gr.print("buf length: "..#buf)
            local flags = gr.mspHelper.readU8(buf)
            summary.ready = bit32.band(flags, 1) ~= 0
            summary.supported = bit32.band(flags, 2) ~= 0
            summary.sectors = gr.mspHelper.readU32(buf)
            summary.totalSize = gr.mspHelper.readU32(buf)
            summary.usedSize = gr.mspHelper.readU32(buf)
            --gr.print("summary.ready: "..tostring(summary.ready))
            --gr.print("summary.supported: "..tostring(summary.supported))
            --gr.print("summary.sectors: "..tostring(summary.sectors))
            --gr.print("summary.totalSize: "..tostring(summary.totalSize))
            --gr.print("summary.usedSize: "..tostring(summary.usedSize))

            callback(callbackParam, summary)
        end,
        simulatorResponse = { 3, 1,0,0,0, 0,4,0,0, 0,3,0,0 }
    }
    gr.mspQueue:add(message)
end

local function eraseDataflash(callback, callbackParam)
    local message = {
        command = 72, -- MSP_DATAFLASH_ERASE
        processReply = function(self, buf)
            local summary = {}
            --gr.print("buf length: "..#buf)
            callback(callbackParam, summary)
        end,
        simulatorResponse = { }
    }
    gr.mspQueue:add(message)
end

return {
    getDataflashSummary = getDataflashSummary,
    eraseDataflash = eraseDataflash
}