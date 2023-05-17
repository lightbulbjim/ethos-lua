-- Aux Trims widget
-- Displays the current value of the two aux trims

--[[
TODO:
  * Auto hide disabled trims.
  * Name translations.
  * Readme.
--]]

local translations = { en = "Aux Trims" }

local function name()
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local function create()
  return {
    trims = {
      left = { enabled = true, member = 4, value = 0 },
      right = { enabled = true, member = 5, value = 0 },
    },
    showBars = true,
    verticalDisplay = false,
  }
end

local function configure(widget)
  local line = form.addLine("Bar indicators")
  form.addBooleanField(line, nil,
      function()
        return widget.showBars
      end,
      function(value)
        widget.showBars = value
      end)

  line = form.addLine("Vertical display")
  form.addBooleanField(line, nil,
      function()
        return widget.verticalDisplay
      end,
      function(value)
        widget.verticalDisplay = value
      end)

  line = form.addLine("T5")
  form.addBooleanField(line, nil,
      function()
        return widget.trims.left.enabled
      end,
      function(value)
        widget.trims.left.enabled = value
      end)

  line = form.addLine("T6")
  form.addBooleanField(line, nil,
      function()
        return widget.trims.right.enabled
      end,
      function(value)
        widget.trims.right.enabled = value
      end)

end

-- Format raw source values as percentage strings
local function format(value)
  local p = (value / 1024) * 100
  if p == 0 then
    return "0"
  else
    return string.format("%+." .. 0 .. "f", p)
  end
end

-- For a given bar length and value, calculate the fill length from centre
local function barFill(length, value)
  return length * value / 1024
end

local function paint(widget)
  local w, h = lcd.getWindowSize()
  local border = 6

  if widget.showBars then
    local barThickness = 6

    if widget.verticalDisplay then
      local vScale = (h - (border * 2)) / 2
      local vOffset = h / 2

      if widget.trims.left.enabled then
        lcd.drawFilledRectangle(border, vOffset, barThickness,
            -barFill(vScale, widget.trims.left.value))
      end

      if widget.trims.right.enabled then
        lcd.drawFilledRectangle(w - border - barThickness, vOffset, barThickness,
            -barFill(vScale, widget.trims.right.value))
      end
    else
      local hScale = (w - (border * 3)) / 4
      local hOffset = border + hScale

      if widget.trims.left.enabled then
        lcd.drawFilledRectangle(hOffset, h - border - barThickness,
            barFill(hScale, widget.trims.left.value), barThickness)
      end

      if widget.trims.right.enabled then
        lcd.drawFilledRectangle(w - hOffset, h - border - barThickness,
            barFill(hScale, widget.trims.right.value), barThickness)
      end

    end

    border = (border * 2) + barThickness
  end

  if h < 80 then
    lcd.font(FONT_S)
  else
    lcd.font(FONT_L)
  end

  local _, textHeight = lcd.getTextSize("")
  local vOffset
  if widget.verticalDisplay then
    vOffset = (h - textHeight) / 2
  else
    vOffset = h - border - textHeight
  end

  if widget.trims.left.enabled then
    lcd.drawText(border, vOffset, format(widget.trims.left.value), LEFT)
  end

  if widget.trims.right.enabled then
    lcd.drawText(w - border, vOffset, format(widget.trims.right.value), RIGHT)
  end
end

local function wakeup(widget)
  local changed = false

  for _, trim in pairs(widget.trims) do
    local source = system.getSource({ category = CATEGORY_TRIM, member = trim.member })

    if trim.value ~= source:value() then
      trim.value = source:value()
      changed = true
    end
  end

  if changed then
    lcd.invalidate()
  end
end

local function init()
  system.registerWidget({
    key = "auxtrms",
    name = name,
    create = create,
    configure = configure,
    wakeup = wakeup,
    paint = paint
  })
end

return { init = init }