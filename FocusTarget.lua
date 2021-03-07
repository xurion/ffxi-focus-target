_addon.name = 'FocusTarget'
_addon.author = 'Dean James (Xurion of Bismarck)'
_addon.command = 'ft'
_addon.version = '1.0.0'

config = require('config')
texts  = require('texts')
images = require('images')

local defaults = {}
defaults.pos = {}
defaults.pos.x = 0
defaults.pos.y = 0
settings = config.load(defaults)

tracking = nil

setup = {}
setup.flags = {}
setup.flags.draggable = false

background = images.new(setup)
background:path(windower.addon_path .. 'img/bg.png')
background:repeat_xy(1, 1)
background:draggable(false)
background:fit(true)

hp_text = texts.new(setup)
hp_text:bg_visible(false)
hp_text:color(255, 189, 193)
hp_text:size(16)
hp_text:stroke_transparency(100)
hp_text:stroke_color(95, 25, 27)
hp_text:stroke_width(1)
hp_text_offset_x = 0
hp_text_offset_y = 25

hp_percentage = images.new(setup)
hp_percentage:path('')
hp_percentage_offset_x = 1
hp_percentage_offset_y = 57
hp_percentage:color(255, 189, 193)
hp_percentage_max_width = 376

function set_hp_percentage(percent)
  hp_percentage:size(hp_percentage_max_width * (percent / 100), 10)
end

function show()
  background:show()
  hp_text:show()
  hp_percentage:show()
end

function hide()
  background:hide()
  hp_text:hide()
  hp_percentage:hide()
end

function update_position()
    background:pos(settings.pos.x, settings.pos.y)
    hp_text:pos(settings.pos.x + hp_text_offset_x, settings.pos.y + hp_text_offset_y)
    hp_percentage:pos(settings.pos.x + hp_percentage_offset_x, settings.pos.y + hp_percentage_offset_y)
end

commands = {}

commands.focus = function()
  local target = windower.ffxi.get_mob_by_target('t')
  if not target or target.id == tracking then
    tracking = nil
    hide()
    return
  end

  tracking = target.id
end

commands.pos = function(axis, position)
    if axis ~= 'x' and axis ~= 'y' or not position then
        windower.add_to_chat(8, 'Bad position arguments. Example: //ft pos x 100')
        return
    end

    settings.pos[axis] = tonumber(position)
    settings:save()
    update_position()
end

commands.help = function()
    windower.add_to_chat(8, 'FocusTarget:')
    windower.add_to_chat(8, '  //ft - toggle focus on current target')
    windower.add_to_chat(8, '  //ft focus - same as above')
    windower.add_to_chat(8, '  //ft pos <x|y> <position> - set the x or y position')
    windower.add_to_chat(8, '  //ft help - display this help')
end

windower.register_event('addon command', function(command, ...)
  command = command and command:lower() or 'focus'

  if commands[command] then
    commands[command](...)
  else
    commands.help()
  end
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
    tracking = nil
    hide()
    return
  end

  -- mob is still a valid target, but is dead (just killed, model still visible)
  if focused_target.hpp == 0 then
    --grey
  else -- mob is alive
    --?
  end

  hp_text:text(focused_target.hpp .. '% ' .. focused_target.name)
  set_hp_percentage(focused_target.hpp)
  show()
end)

update_position()
