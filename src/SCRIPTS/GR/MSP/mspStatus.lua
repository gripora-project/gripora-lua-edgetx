local function getStatus(callback, callbackParam)
    local message = {
        command = 101, -- MSP_STATUS
        processReply = function(self, buf)
            local status = {}
            --status.pidCycleTime = gr.mspHelper.readU16(buf)
            --status.gyroCycleTime = gr.mspHelper.readU16(buf)
            buf.offset = 7
            status.flightModeFlags = gr.mspHelper.readU32(buf)
            buf.offset = 12
            status.realTimeLoad = gr.mspHelper.readU16(buf)
            --gr.print("Real-time load: "..tostring(status.realTimeLoad))
            status.cpuLoad = gr.mspHelper.readU16(buf)
            --gr.print("CPU load: "..tostring(status.cpuLoad))
            buf.offset = 18
            status.armingDisableFlags = gr.mspHelper.readU32(buf)
            --gr.print("Arming disable flags: "..tostring(status.armingDisableFlags))
            buf.offset = 24
            status.profile = gr.mspHelper.readU8(buf)
            --gr.print("Profile: "..tostring(status.profile))
            --status.numProfiles = gr.mspHelper.readU8(buf)
            buf.offset = 26
            status.rateProfile = gr.mspHelper.readU8(buf)
            --status.numRateProfiles = gr.mspHelper.readU8(buf)
            buf.offset = 28
            status.motorCount = gr.mspHelper.readU8(buf)
            --gr.print("Number of motors: "..tostring(status.motorCount))
            --status.servoCount = gr.mspHelper.readU8(buf)
            --gr.print("Number of servos: "..tostring(status.servoCount))
            callback(callbackParam, status)
        end,
        simulatorResponse = { 240, 1, 124, 0, 35, 0, 0, 0, 0, 0, 0, 224, 1, 10, 1, 0, 26, 0, 0, 0, 0, 0, 2, 0, 6, 0, 6, 2, 4, 1 }
    }

    gr.mspQueue:add(message)
end

return {
    getStatus = getStatus
}