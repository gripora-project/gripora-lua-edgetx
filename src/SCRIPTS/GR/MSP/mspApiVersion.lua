-- Gripora MSP API 33.0: the first version that is Gripora's own (WingFlight
-- stays on 22.x), with the MSP2_GRIPORA_* messages. Every 33.x is accepted;
-- older firmware is refused.
local REQUIRED_API_MAJOR = 33
local REQUIRED_API_MINOR = 0

local function makeVersion(major, minor)
    return major + minor / 100 + 0.00001
end

local function versionString(major, minor)
    return string.format("%d.%02d", major, minor)
end

local function requiredVersionString()
    return versionString(REQUIRED_API_MAJOR, REQUIRED_API_MINOR)
end

local function isSupported(major, minor)
    return major == REQUIRED_API_MAJOR and minor ~= nil and minor >= REQUIRED_API_MINOR
end

local function getApiVersion(callback, callbackParam)
    local message = {
        command = 1, -- MSP_API_VERSION
        processReply = function(self, buf)
            if #buf >= 3 then
                local major = buf[2]
                local minor = buf[3]
                callback(callbackParam, makeVersion(major, minor), major, minor)
            end
        end,
        simulatorResponse = { 0, REQUIRED_API_MAJOR, REQUIRED_API_MINOR }
    }
    gr.mspQueue:add(message)
end

return {
    getApiVersion = getApiVersion,
    isSupported = isSupported,
    requiredVersionString = requiredVersionString,
    versionString = versionString,
}
