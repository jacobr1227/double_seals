local mod_id = "sealAPI"
local mod_name = "Seal API"
local mod_version = "0.85"
local mod_author = "jacobr1227"

local loc_list = {}

-- Seal_id MUST contain no spaces or lua-unsafe characters.
-- Image name in assets/ must match the seal_id, but lowercase and adding _seal at the end.
-- Note: function code will need to be added manually. Refer to https://github.com/jacobr1227/double_seals/double_seals.lua for examples
function add_seal(seal_id, label, color, shader, desc)
    -- Prepare the data contents, add to the pools.
    local loc_id = string.lower(seal_id) .. "_seal"
    table.insert(loc_list, loc_id)
    local data = {}
    data.set = 'Seal'
    data.discovered = false
    data.key = seal_id
    data.order = #G.P_CENTER_POOLS.Seal + 1
    G.P_SEALS[seal_id] = data
    table.insert(G.P_CENTER_POOLS['Seal'], data)
    desc.name = label

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
    for _, line in ipairs(type(newSealText.name) == 'table' and newSealText.name or {seal_id}) do
        newSealText.name_parsed[#newSealText.name_parsed + 1] = loc_parse_string(line)
    end

    -- Inserts localization items and sprites.
    G.localization.descriptions.Other[loc_id] = newSealText
    G.localization.misc.labels[loc_id] = label
    G.ASSET_ATLAS[loc_id] = {}
    G.ASSET_ATLAS[loc_id].name = loc_id
    G.ASSET_ATLAS[loc_id].image = love.graphics.newImage("assets/" .. G.SETTINGS.GRAPHICS.texture_scaling .. "x/" ..
                                                             loc_id .. ".png", {
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

    -- I like sorted tables :)
    for k, v in pairs(G.P_SEALS) do
        table.sort(v, function(a, b)
            return a.order < b.order
        end)
    end
    table.sort(G.P_CENTER_POOLS["Seal"], function(a, b)
        return a.order < b.order
    end)
end

function inject_overrides()
    local info_queues = [[local info_queue = {}
    if first_pass and not (_c.set == 'Edition') and badges then
        for k, v in ipairs(badges) do
            ]]
    if #loc_list > 0 then
        for i = 1, #loc_list do
            info_queues = info_queues ..
                              string.format(
                    [[if v == '%s' then info_queue[#info_queue + 1] = {key = '%s', set = 'Other'} end
            ]], loc_list[i], loc_list[i])
        end
        info_queues = info_queues .. [[end
    end]]
        inject("functions/common_events.lua", "generate_card_ui", "local info_queue = {}", info_queues)
    end
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
end

function add_shader(seal_id, shader)
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

--Checks how many potential replacements would occur with an injection. Used to check if inject targets are valid.
function inject_checker(path, function_name, to_replace, replacement)
    local function_body = extractFunctionBody(path, function_name)
    local modified_function_code, num_replacements = function_body:gsub(to_replace, replacement)
    return num_replacements
end

function eat(waste, this)
    --This function intentionally does absolutely nothing.
    --It is used as filler in replacements to fix inject()'s faults
    if waste then
        sendDebugMessage(waste)
    end
    if this then
        sendDebugMessage("This!")
    end
end