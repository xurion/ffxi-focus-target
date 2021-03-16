_addon.name = 'FocusTarget'
_addon.author = 'Dean James (Xurion of Bismarck)'
_addon.command = 'ft'
_addon.version = '2.0.0'

config = require('config')
texts  = require('texts')
images = require('images')
res = require('resources')

local defaults = {}
defaults.pos = {}
defaults.pos.x = 0
defaults.pos.y = 0
defaults.title = true
settings = config.load(defaults)

tracking = nil

setup = {}
setup.flags = {}
setup.flags.draggable = false

title = texts.new(setup)
title:bg_visible(false)
title:size(20)
title:stroke_transparency(100)
title:stroke_width(1)
title:color(252, 245, 173)
title:bold(true)
title:text('FOCUS TARGET')
title_offset_x = -2
title_offset_y = -6

hp_text = texts.new(setup)
hp_text:bg_visible(false)
hp_text:size(16)
hp_text:stroke_transparency(100)
hp_text:stroke_width(1)
hp_text:bold(false)
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

ability_icon = images.new(setup)
ability_icon:repeat_xy(1, 1)
ability_icon:draggable(false)
ability_icon:fit(true)
ability_icon_offset_x = 0
ability_icon_offset_y = 70

ability_text = texts.new(setup)
ability_text:bg_visible(false)
ability_text:size(14)
ability_text:stroke_transparency(100)
ability_text:stroke_width(1)
ability_text_offset_x = 30
ability_text_offset_y = 75

hp_colors = {
    player = { 233, 255, 253 },
    npc = { 185, 255, 163 },
    unclaimed = { 252, 245, 173 },
    claimed = { 255, 189, 193 },
    outclaimed = { 252, 173, 252 },
    cfh = { 255, 208, 106 },
    defeated = { 152, 152, 152 }
}

hp_stroke_colors = {
    player = { 30, 107, 76 },
    npc = { 82, 227, 36 },
    unclaimed = { 173, 150, 54 },
    claimed = { 190, 84, 84 },
    outclaimed = { 156, 44, 156 },
    cfh = { 166, 115, 0 },
    defeated = { 72, 72, 72 }
}

element_colors = {
    [0] = { 240, 110, 110 }, --fire
    [1] = { 77, 212, 219 }, --ice
    [2] = { 126, 211, 33 }, --wind
    [3] = { 237, 161, 34 }, --earth
    [4] = { 212, 57, 198 }, --lightning
    [5] = { 69, 134, 210 }, --water
    [6] = { 255, 255, 255 }, --light
    [7] = { 0, 0, 0 }, --dark
    [15] = { 255, 255, 255 }, --none
    tp = { 181, 47, 22 },
    item = { 133, 79, 24 }
}

function with_element_color(element, text)
    if not element then return text end
    return ' \\cs(' .. table.concat(element_colors[element], ",") .. ')' .. text .. '\\cr'
end

function set_ability(ability, element, target)
    local text = with_element_color(element, ability)
    if target then
        text = text .. ' >>> ' .. target
    end
    local img = element or 'none' -- Have to use transparent image due to bug in images lib
    ability_icon:path(windower.addon_path .. 'img/elements/' .. img .. '.png')
    ability_text:text(text)
end

function is_player(target)
    return target.spawn_type == 1 or target.spawn_type == 13
end

function set_hp_colors_for_target(target)
    local color = 'unclaimed'

    if is_player(target) then
        color = 'player'
    elseif target.spawn_type == 2 or target.spawn_type == 14 then
        color = 'npc'
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
                color = 'claimed'
            else
                color = 'outclaimed'
            end
        elseif target.status == 2 or target.status == 3 then
            color = 'defeated'
        end
    end

    hp_bg:path(windower.addon_path .. 'img/' .. color .. '-hp.png')
    hp_percentage:color(hp_colors[color][1], hp_colors[color][2], hp_colors[color][3])
    hp_text:color(hp_colors[color][1], hp_colors[color][2], hp_colors[color][3])
    hp_text:stroke_color(hp_stroke_colors[color][1], hp_stroke_colors[color][2], hp_stroke_colors[color][3])
end

function set_hp_percentage(percent)
    hp_percentage:size(hp_percentage_max_width * (percent / 100), 10)
end

function show()
    if settings.title then
        title:show()
    end
    hp_text:show()
    hp_bg:show()
    hp_percentage:show()
    ability_text:show()
    ability_icon:show()
end

function hide()
    title:hide()
    hp_text:hide()
    hp_bg:hide()
    hp_percentage:hide()
    ability_text:hide()
    ability_icon:hide()
end

function refresh_ui()
    hide()
    show()
end

function update_position()
    title:pos(settings.pos.x + title_offset_x, settings.pos.y + title_offset_y)
    hp_text:pos(settings.pos.x + hp_text_offset_x, settings.pos.y + hp_text_offset_y)
    hp_bg:pos(settings.pos.x + hp_bg_offset_x, settings.pos.y + hp_bg_offset_y)
    hp_percentage:pos(settings.pos.x + hp_percentage_offset_x, settings.pos.y + hp_percentage_offset_y)
    ability_text:pos(settings.pos.x + ability_text_offset_x, settings.pos.y + ability_text_offset_y)
    ability_icon:pos(settings.pos.x + ability_icon_offset_x, settings.pos.y + ability_icon_offset_y)
end

commands = {}

commands.focus = function()
    local target = windower.ffxi.get_mob_by_target('t')
    if not target or target.id == tracking then
        tracking = nil
        hide()
        return
     end

    set_ability('')
    tracking = target.id
end

commands.pos = function(x, y)
    if not x or not y then
        windower.add_to_chat(8, 'Current x and y position: ' .. settings.pos.x .. ', ' .. settings.pos.y)
        windower.add_to_chat(8, 'To set the position: //ft pos 100 200')
        return
    end

    settings.pos.x = tonumber(x)
    settings.pos.y = tonumber(y)
    settings:save()
    update_position()
end

commands.title = function()
    settings.title = not settings.title
    settings:save()
    refresh_ui()
end

commands.help = function()
    windower.add_to_chat(8, 'FocusTarget:')
    windower.add_to_chat(8, '  //ft - toggle focus on current target')
    windower.add_to_chat(8, '  //ft pos - show the current x and y position')
    windower.add_to_chat(8, '  //ft pos <x> <y> - set the x and y position')
    windower.add_to_chat(8, '  //ft title - toggle the display of the FOCUS TARGET title')
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

windower.register_event('zone change', function ()
    hide()
end)

windower.register_event('action', function (action)
    if not tracking or action.actor_id ~= tracking then return end

    --[[
        Categories:
            3: Finish weapon skill
            4: Finish casting spell
            5: Finish item use
            7: Begin weapon skill or TP move
            8: Begin spell casting or interrupt casting, param 24931 = start, param 28787 = interupt
            9: Begin item use or interrupt usage
            11: Finish TP move
    ]]

    if action.category == 7 or action.category == 8 then
        -- Interupted
        if action.param == 28787 then
            set_ability('')
            return
        end

        -- Casting new spell or TP move
        local ability_id = action.targets[1].actions[1].param
        local ability_name
        local ability_element
        if action.category == 7 then
            ability_element = 'tp'
            local actor = windower.ffxi.get_mob_by_id(action.actor_id)

            -- Detect if the actor is a player or mob
            if is_player(actor) then
                ability_name = res.weapon_skills[ability_id].name
            else
                ability_name = res.monster_abilities[ability_id].name
            end
        else
            ability_name = res.spells[ability_id].name
            ability_element = res.spells[ability_id].element
        end
        local target_id = action.targets[1].id
        local target_name
        if target_id ~= tracking then
            target_name = windower.ffxi.get_mob_by_id(target_id).name
        end
        set_ability(ability_name, ability_element, target_name)
    elseif action.category == 9 then
        -- Interupted
        if action.param == 28787 then
            set_ability('')
            return
        end

        -- Using item
        local item_id = action.targets[1].actions[1].param
        local item_name = res.items[item_id].name
        local target_id = action.targets[1].id
        local target_name
        if target_id ~= tracking then
            target_name = windower.ffxi.get_mob_by_id(target_id).name
        end
        set_ability(item_name, 'item', target_name)
    elseif action.category == 3 or action.category == 4 or action.category == 5 or action.category == 11 then
        set_ability('')
    end
end)

update_position()
