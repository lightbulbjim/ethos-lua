-- Stick Trims widget
-- Displays the current value of the four stick trims

--[[
TODO:
  * Auto hide disabled trims.
  * Name translations.
  * Readme.
--]]

local translations = { en = "Stick Trims" }

local function name()
  local locale = system.getLocale()
  return translations[locale] or translations["en"]
end

local function create()
  local trims = {
    leftHorizontal = { enabled = true, member = nil, value = 0 },
    leftVertical = { enabled = true, member = nil, value = 0 },
    rightVertical = { enabled = true, member = nil, value = 0 },
    rightHorizontal = { enabled = true, member = nil, value = 0 },
  }

  local mode = system.getStickMode()

  -- Trim member numbers follow RETA, zero indexed
  if mode == 1 then
    trims.leftHorizontal.member = 0
    trims.leftVertical.member = 1
    trims.rightVertical.member = 2
    trims.rightHorizontal.member = 3
  elseif mode == 2 then
    trims.leftHorizontal.member = 0
    trims.leftVertical.member = 2
    trims.rightVertical.member = 1
    trims.rightHorizontal.member = 3
  elseif mode == 3 then
    trims.leftHorizontal.member = 3
    trims.leftVertical.member = 1
    trims.rightVertical.member = 2
    trims.rightHorizontal.member = 0
  elseif mode == 4 then
    trims.leftHorizontal.member = 3
    trims.leftVertical.member = 2
    trims.rightVertical.member = 1
    trims.rightHorizontal.member = 0
  end

  return {
    trims = trims,
    showBars = true,
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

  local function findTrim(member)
    for _, v in pairs(widget.trims) do
      if v.member == member then
        return v
      end
    end
  end

  line = form.addLine("Rudder")
  form.addBooleanField(line, nil,
      function()
        return findTrim(0).enabled
      end,
      function(value)
        findTrim(0).enabled = value
      end)

  line = form.addLine("Elevator")
  form.addBooleanField(line, nil,
      function()
        return findTrim(1).enabled
      end,
      function(value)
        findTrim(1).enabled = value
      end)

  line = form.addLine("Throttle")
  form.addBooleanField(line, nil,
      function()
        return findTrim(2).enabled
      end,
      function(value)
        findTrim(2).enabled = value
      end)

  line = form.addLine("Aileron")
  form.addBooleanField(line, nil,
      function()
        return findTrim(3).enabled
      end,
      function(value)
        findTrim(3).enabled = value
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
  local topBorder = border

  if widget.showBars then
    local barThickness = 6

    local vScale, vOffset
    if widget.trims.leftHorizontal.enabled or widget.trims.rightHorizontal.enabled then
      vScale = (h - (border * 3) - barThickness) / 2
      vOffset = (h - border - barThickness) / 2
    else
      vScale = (h - (border * 2)) / 2
      vOffset = h / 2
    end

    if widget.trims.leftVertical.enabled then
      lcd.drawFilledRectangle(border, vOffset, barThickness,
          -barFill(vScale, widget.trims.leftVertical.value))
    end

    if widget.trims.rightVertical.enabled then
      lcd.drawFilledRectangle(w - border - barThickness, vOffset, barThickness,
          -barFill(vScale, widget.trims.rightVertical.value))
    end

    local hScale = (w - (border * 3)) / 4
    local hOffset = border + hScale

    if widget.trims.leftHorizontal.enabled then
      lcd.drawFilledRectangle(hOffset, h - border - barThickness,
          barFill(hScale, widget.trims.leftHorizontal.value), barThickness)
    end

    if widget.trims.rightHorizontal.enabled then
      lcd.drawFilledRectangle(w - hOffset, h - border - barThickness,
          barFill(hScale, widget.trims.rightHorizontal.value), barThickness)
    end

    border = (border * 2) + barThickness
  end

  local vOffset, hOffset

  if h < 60 then
    lcd.font(FONT_S)
    vOffset = 0
    hOffset = 35
  elseif h < 80 then
    lcd.font(FONT_S)
    vOffset = 0
    hOffset = 25
  elseif h < 90 then
    lcd.font(FONT_L)
    vOffset = 5
    hOffset = 10
  elseif h < 110 then
    lcd.font(FONT_L)
    vOffset = 15
    hOffset = 10
  else
    lcd.font(FONT_L)
    vOffset = 40
    hOffset = 10
  end

  local _, textHeight = lcd.getTextSize("")

  if widget.trims.leftVertical.enabled then
    lcd.drawText(border, topBorder + vOffset,
        format(widget.trims.leftVertical.value), LEFT)
  end

  if widget.trims.rightVertical.enabled then
    lcd.drawText(w - border, topBorder + vOffset,
        format(widget.trims.rightVertical.value), RIGHT)
  end

  if widget.trims.leftHorizontal.enabled then
    lcd.drawText(border + hOffset, h - border - textHeight,
        format(widget.trims.leftHorizontal.value), LEFT)
  end

  if widget.trims.rightHorizontal.enabled then
    lcd.drawText(w - border - hOffset, h - border - textHeight,
        format(widget.trims.rightHorizontal.value), RIGHT)
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
    key = "stktrms",
    name = name,
    create = create,
    configure = configure,
    wakeup = wakeup,
    paint = paint
  })
end

return { init = init }