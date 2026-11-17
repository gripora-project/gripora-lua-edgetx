local function getFeatureConfig(callback, callbackParam)
    local message = {
        command = 36, -- MSP_FEATURE_CONFIG
        processReply = function(self, buf)
            local config = {}
            --gr.print("buf length: "..#buf)
            config.bitfield = gr.mspHelper.readU32(buf)
            callback(callbackParam, config)
        end,
        simulatorResponse = { 8, 4, 0, 124 }
    }
    gr.mspQueue:add(message)
end

return {
    getFeatureConfig = getFeatureConfig,
    telemetryIsEnabled = function(bitfield)
        return bit32.btest(bitfield, bit32.lshift(1, 10)) -- FEATURE_TELEMETRY = BIT(10)
    end
}
