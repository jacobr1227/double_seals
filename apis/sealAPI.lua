local mod_id = "sealAPI"
local mod_name = "Seal API"
local mod_version = "2.0"
local mod_author = "jacobr1227"

local loc_list = {}
local seal_list = {}
local first_pass = true

--Bugs:
    --In the Seal Collection menu, the card's title will be incorrect, using the seal_id instead of the label. This only affects the collection.
-- Seal_id MUST contain no spaces or lua-unsafe characters.
-- Image name in assets/ must match the seal_id, but lowercase and adding _seal at the end.
-- Note: function code will need to be added manually. Refer to https://github.com/jacobr1227/double_seals/double_seals.lua for examples
function add_seal(seal_id, label, color, shader, desc)
    -- Prepare the data contents, add to the pools.
    local loc_id = string.lower(seal_id) .. "_seal"
    loc_list[string.lower(seal_id)] = {loc_id=loc_id, color=color, queued=false}
    local data = {}
    data.set = 'Seal'
    data.discovered = false
    data.key = seal_id
    data.order = #G.P_CENTER_POOLS.Seal + 1
    G.P_SEALS[seal_id] = data
    table.insert(G.P_CENTER_POOLS['Seal'], data)
    desc.name = label
    table.insert(seal_list, data)

    -- Parse localization text.
    local newSealText = {
        name = desc.name,
        text = desc.text,
        text_parsed = {},
        name_parsed = {}
    }
    for _, line in ipairs(desc.text) do
        newSealText.text_parsed[#newSealText.text_parsed + 1] = loc_parse_string(line)
    end
    for _, line in ipairs(type(newSealText.name) == 'table' and newSealText.name or {label}) do
        newSealText.name_parsed[#newSealText.name_parsed + 1] = loc_parse_string(line)
    end

    -- Inserts localization items and sprites.
    G.localization.descriptions.Other[loc_id] = newSealText
    G.localization.misc.labels[loc_id] = label
    G.ASSET_ATLAS[loc_id] = {}
    G.ASSET_ATLAS[loc_id].name = loc_id
    G.ASSET_ATLAS[loc_id].image = love.graphics.newImage("assets/" .. G.SETTINGS.GRAPHICS.texture_scaling .. "x/" ..loc_id .. ".png", {
        mipmaps = true,
        dpiscale = G.SETTINGS.GRAPHICS.texture_scaling
    })
    G.ASSET_ATLAS[loc_id].px = 71
    G.ASSET_ATLAS[loc_id].py = 95
    G.shared_seals[seal_id] = Sprite(0, 0, G.CARD_W, G.CARD_H, G.ASSET_ATLAS[loc_id], {
        x = 0,
        y = 0
    })

    if shader then
        add_shader(seal_id, shader)
    end

    -- Inserting colors for badges/etc.
    local color_string = string.format([[purple_seal = G.C.PURPLE,
    %s = %s]], loc_id, "G.C." .. string.upper(color) .. ',')
    inject("functions/UI_definitions.lua", "get_badge_colour", "purple_seal = G.C.PURPLE,", color_string)

    -- Sort your tables
    for k, v in pairs(G.P_SEALS) do
        table.sort(v, function(a, b)
            return a.order < b.order
        end)
    end
    table.sort(G.P_CENTER_POOLS["Seal"], function(a, b)
        return a.order < b.order
    end)
end

function remove_seals()
    for k, v in pairs(seal_list) do
        local loc_id = string.lower(k) .. "_seal"
        table.remove(G.P_CENTER_POOLS['Seal'], v)
        G.P_SEALS[k] = nil
        G.localization.descriptions.Other[loc_id] = nil
        G.localization.misc.labels[loc_id] = nil
        G.ASSET_ATLAS[loc_id] = nil
        G.shared_seals[k] = nil
    end
end

--Run this at the end.
function inject_overrides()
    --Injects the info_queues for badge/UI data
    local info_queues = [[local info_queue = {}
    if first_pass and not (_c.set == 'Edition') and badges then
        for k, v in ipairs(badges) do
            ]]
    local count = 0
    for _ in pairs(loc_list) do count = count + 1 end
    if count > 0 then
        for k, v in pairs(loc_list) do
            if v.queued == false then
                info_queues = info_queues ..string.format([[if v == '%s' then info_queue[#info_queue + 1] = {key = '%s', set = 'Other'} end
                ]], v.loc_id, v.loc_id)
                loc_list[k].queued = true
            end
        end
        info_queues = info_queues .. [[end
    end]]
        inject("functions/common_events.lua", "generate_card_ui", "local info_queue = {}", info_queues)
    end

    --Injects the new seal generator code to both places it is seen
    if first_pass then
        local fun_name = "Card:open"
        local file_name = "card.lua"
        local to_replace = "local seal_type = pseudorandom"
        local replacement = [[local seal_type = pseudorandom(pseudoseed('stdsealtype'..G.GAME.round_resets.ante), 1, #G.P_CENTER_POOLS['Seal'])
            local sealName
                for k, v in pairs(G.P_SEALS) do
                    if v.order == seal_type then 
                        sealName = k
                        card:set_seal(sealName)
                    end
                end--]]
        inject(file_name, fun_name, "card:set_seal", "eat")
        inject(file_name, fun_name, to_replace, replacement)
        local to_replace = "local seal_type = pseudorandom"
        local replacement = [[local seal_type = pseudorandom(pseudoseed('certsl'), 1, #G.P_CENTER_POOLS['Seal'])
            local sealName
            for k, v in pairs(G.P_SEALS) do
                if v.order == seal_type then 
                    sealName = k
                    _card:set_seal(sealName, true)
                end
            end
            local throwaway = pseudorandom]]
        fun_name = "Card:calculate_joker"
        inject(file_name, fun_name, "_card:set_seal", "eat")
        inject(file_name, fun_name, to_replace, replacement)
    end
end

--If you're creating another card that references a Seal object in its description, run this to add that tooltip.
--Example input: set="Spectral", name="Deja Vu", seal_id="Red" or "red"
--This function will generate the necessary colors for any text using the given color of the added seal.
function inject_seal_infotip(set, name, seal_id)
    local loc_id = loc_list[string.lower(seal_id)].loc_id
    local color = loc_list[string.lower(seal_id)].color
    local info_queue = string.format([[local info_queue = {}
    if _c.set == '%s' then
        if _c.name == '%s' then info_queue[#info_queue+1] = {key = '%s', set = 'Other'}
            ]], set, name, loc_id)
    info_queue = info_queue .. [[end
        end]]
    inject("functions/common_events.lua", "generate_card_ui", "local info_queue = {}", info_queue)
    if G.C[string.upper(color)] then
        local replacement = string.format([[red = G.C.RED,
        %s = G.C.%s,]], string.lower(color), string.upper(color))
        inject("functions/misc_functions.lua", "loc_colour", "red = G.C.RED,", replacement)
    else
        sendDebugMessage("Invalid color provided. Please use a valid color from globals.lua.")
    end
end

function add_shader(seal_id, shader)
    --If the seal object contains a valid shader label, redraws the sprite and renders a new shader on top.
    --Not performance optimized.
    local valid_shader = {
        dissolve = true,
        voucher = true,
        vortex = true,
        negative = true,
        holo = true,
        foil = true,
        debuff = true,
        polychrome = true,
        hologram = true,
        played = true
    }
    if valid_shader[shader] ~= nil then
        local replacement = string.format([[if self.seal then
        if self.seal == '%s' then
            G.shared_seals[self.seal].role.draw_major = self
            G.shared_seals[self.seal]:draw_shader('dissolve', nil, nil, nil, self.children.center)
            G.shared_seals[self.seal]:draw_shader('%s', nil, self.ARGS.send_to_shader, nil, self.children.center) 
        end
    end]], seal_id, shader)
        injectTail("card.lua", "Card:draw", replacement)
    else
        sendDebugMessage("Error: invalid shader.")
    end
end

-- Debug tools for various purposes.
--Dumps table data to the caller
function dump(o)
    if o == nil then
        return "nil."
    end
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

--Checks how many potential replacements would occur with an injection. Used to check if inject targets are valid to test injects.
function inject_checker(path, function_name, to_replace, replacement)
    local function_body = extractFunctionBody(path, function_name)
    local modified_function_code, num_replacements = function_body:gsub(to_replace, replacement)
    return num_replacements
end

function eat(waste, this)
    --This function intentionally does absolutely nothing.
    --It is used as filler in replacements within inject_overrides() to fix inject()'s faults
end