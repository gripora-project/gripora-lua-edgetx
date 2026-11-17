local subtitle = ...

local function canUseDynamicSubtitle()
    -- Dynamic subtitles work on EdgeTX 2.11.4 or higher
    local name, version, major, minor, patch = getVersion()
    --gr.print("EdgeTX version %d.%d.%d", major, minor, patch)
    return lcd.setColor and
        (major >= 3 or
        (major == 2 and minor >= 12) or
        (major == 2 and minor >= 11 and patch >= 4))
end

if not (gr.widget and gr.widget.options and canUseDynamicSubtitle()) then
    return subtitle
end

return function()
    return subtitle .. gr.widget.options:getText()
end
