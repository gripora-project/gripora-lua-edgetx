local lcdShared = ...

local t = {
    text = nil
}

t.update = function()
    if not t.text then return end

    lcd.drawFilledRectangle(gr.radio.SaveBox.x, gr.radio.SaveBox.y, gr.radio.SaveBox.w, gr.radio.SaveBox.h, lcdShared.backgroundFill)
    lcd.drawRectangle(gr.radio.SaveBox.x, gr.radio.SaveBox.y, gr.radio.SaveBox.w, gr.radio.SaveBox.h, SOLID)
    lcd.drawText(gr.radio.SaveBox.x + gr.radio.SaveBox.x_offset, gr.radio.SaveBox.y + gr.radio.SaveBox.h_offset, t.text, DBLSIZE + lcdShared.textOptions)
end

return t