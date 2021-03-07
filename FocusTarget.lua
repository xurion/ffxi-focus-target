_addon.name = 'FocusTarget'
_addon.author = 'Dean James (Xurion of Bismarck)'
_addon.command = 'ft'
_addon.version = '2.0.0'

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
background:path(windower.addon_path .. 'img/title.png')
background:repeat_xy(1, 1)
background:draggable(false)
background:fit(true)

hp_text = texts.new(setup)
hp_text:bg_visible(false)
hp_text:size(16)
hp_text:stroke_transparency(100)
hp_text:stroke_width(1)
hp_text_offset_x = 0
hp_text_offset_y = 25

hp_bg = images.new(setup)
hp_bg:repeat_xy(1, 1)
hp_bg:draggable(false)
hp_bg:fit(true)
hp_bg_offset_x = 0
hp_bg_offset_y = 56

hp_percentage = images.new(setup)
hp_percentage:path('')
hp_percentage_offset_x = 1
hp_percentage_offset_y = 57
hp_percentage_max_width = 376

hp_colors = {
    player = { 233, 255, 253 },
    npc = { 185, 255, 163 },
    unclaimed = { 252, 245, 173 },
    claimed = { 255, 189, 193 },
    otherclaimed = { 252, 173, 252 },
    cfh = { 255, 208, 106 },
    defeated = { 152, 152, 152 }
}

hp_stroke_colors = {
    player = { 30, 107, 76 },
    npc = { 82, 227, 36 },
    unclaimed = { 173, 150, 54 },
    claimed = { 190, 84, 84 },
    otherclaimed = { 156, 44, 156 },
    cfh = { 166, 115, 0 },
    defeated = { 72, 72, 72 }
}

function set_hp_colors_for_target(target)
    local bar_percentage = hp_colors.unclaimed
    local text = hp_colors.unclaimed
    local stroke = hp_stroke_colors.unclaimed
    local img = 'unclaimed-hp.png'

    if target.spawn_type == 1 or target.spawn_type == 13 then
        bar_percentage = hp_colors.player
        text = hp_colors.player
        stroke = hp_stroke_colors.player
        img = 'player-hp.png'
    elseif target.spawn_type == 2 then
        bar_percentage = hp_colors.npc
        text = hp_colors.npc
        stroke = hp_stroke_colors.npc
        img = 'npc-hp.png'
    elseif target.spawn_type == 16 then
        if target.status == 1 then
            local party = windower.ffxi.get_party()
            local party_claimed = false
            for i = 0, 5 do
                if not party['p' .. i] then
                    break
                end
                if party['p' .. i].mob.id == target.claim_id then
                    party_claimed = true
                    break
                end
            end

            if party_claimed then
                bar_percentage = hp_colors.claimed
                text = hp_colors.claimed
                stroke = hp_stroke_colors.claimed
                img = 'party-claimed-hp.png'
            else
                bar_percentage = hp_colors.otherclaimed
                text = hp_colors.otherclaimed
                stroke = hp_stroke_colors.otherclaimed
                img = 'other-claimed-hp.png'
            end
        elseif target.status == 2 or target.status == 3 then
            text = hp_colors.defeated
            stroke = hp_stroke_colors.defeated
            img = 'defeated-hp.png'
        end
    end

    hp_bg:path(windower.addon_path .. 'img/' .. img)
    hp_percentage:color(bar_percentage[1], bar_percentage[2], bar_percentage[3])
    hp_text:color(text[1], text[2], text[3])
    hp_text:stroke_color(stroke[1], stroke[2], stroke[3])
end

function set_hp_percentage(percent)
    hp_percentage:size(hp_percentage_max_width * (percent / 100), 10)
end

function show()
  background:show()
  hp_text:show()
  hp_bg:show()
  hp_percentage:show()
end

function hide()
  background:hide()
  hp_text:hide()
  hp_bg:hide()
  hp_percentage:hide()
end

function update_position()
    background:pos(settings.pos.x, settings.pos.y)
    hp_text:pos(settings.pos.x + hp_text_offset_x, settings.pos.y + hp_text_offset_y)
    hp_bg:pos(settings.pos.x + hp_bg_offset_x, settings.pos.y + hp_bg_offset_y)
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
    windower.add_to_chat(8, '  //ft pos <axis> <pos> - set the x or y position')
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

  set_hp_colors_for_target(focused_target)
  set_hp_percentage(focused_target.hpp)
  hp_text:text(focused_target.hpp .. '% ' .. focused_target.name)
  show()
end)

update_position()
