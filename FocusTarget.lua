_addon.name = "FocusTarget"
_addon.author = "Dean James (Xurion of Bismarck)"
_addon.command = "ft"
_addon.version = "1.0.0"

config = require('config')
texts = require("texts")

local defaults = {
  bg = {
    alpha = 75,
    blue = 0,
    green = 0,
    red = 0,
    visible = true
  },
  flags = {
    bold = false,
    bottom = false,
    draggable = true,
    italic = false,
    right = false
  },
  padding = 3,
  pos = {
    x = 1435,
    y = 180
  },
  text = {
    alpha = 255,
    blue = 255,
    font = "Arial",
    fonts = {},
    green = 255,
    red = 255,
    size = 10,
    stroke = {
      alpha = 255,
      blue = 0,
      green = 0,
      red = 0,
      width = 0
    }
  }
}

settings = config.load(defaults)
local ui = texts.new(settings)
local properties = L{}
properties:append('Focus Target')
properties:append('${target_name}')
properties:append('${target_hpp}%')
ui:clear()
ui:append(properties:concat('\n'))

tracking = nil

windower.register_event("addon command", function()
  local target = windower.ffxi.get_mob_by_target('t')
  if not target then
    tracking = nil
    ui:hide()
    return
  end
  tracking = target.id
end)

windower.register_event("prerender", function()
  if not tracking then return end
  local focused_target = windower.ffxi.get_mob_by_id(tracking)
  if not focused_target then
    tracking = nil
    return
  end

  -- target is not in range, or dead and depopped
  if not focused_target.valid_target then
    ui:bg_alpha(25)
    ui:alpha(25)

    -- if the target is dead (model depopped)
    if focused_target.hpp == 0 then
      tracking = nil
    end
    return
  end

  -- mob is still a valid target, but is dead (just killed, model still visible)
  if focused_target.hpp == 0 then
    ui:alpha(50)
  else -- mob is alive
    ui:alpha(defaults.text.alpha)
  end

  ui:bg_alpha(defaults.bg.alpha)
  ui:update({
    target_name = focused_target.name,
    target_hpp = focused_target.hpp
  })
  ui:show()
end)
