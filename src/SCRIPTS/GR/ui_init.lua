local mspApiVersion = gr.useApi("mspApiVersion")
local returnTable = { f = nil, t = "" }
local apiVersion
local apiVersionMajor
local apiVersionMinor
local lastRunTS

local function init()
    if getRSSI() == 0 then
        returnTable.t = "Waiting for connection"
        return false
    end

    if not apiVersion and (not lastRunTS or lastRunTS + 2 < gr.clock()) then
        returnTable.t = "Waiting for API version"
        mspApiVersion.getApiVersion(function(_, version, major, minor)
            apiVersion = version
            apiVersionMajor = major
            apiVersionMinor = minor
        end)
        lastRunTS = gr.clock()
    end

    gr.mspQueue:processQueue()

    if gr.mspQueue:isProcessed() and apiVersion then
        if not mspApiVersion.isSupported(apiVersionMajor, apiVersionMinor) then
            local apiVersionAsString = mspApiVersion.versionString(apiVersionMajor, apiVersionMinor)
            returnTable.t = "This version of the Lua\nscripts can't be used\nwith the selected model\nwhich has version "..apiVersionAsString.."."
                .."\nRequired MSP API: "..mspApiVersion.requiredVersionString()
        else
            -- received correct API version, proceed
            gr.apiVersion = apiVersion
            collectgarbage()
            return true
        end
    end

    return false
end

returnTable.f = init

return returnTable
