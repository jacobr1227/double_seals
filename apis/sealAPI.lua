local mod_id = "sealAPI"
local mod_name = "Seal API"
local mod_version = "0.7"
local mod_author = "jacobr1227"

-- Seal_id MUST contain no spaces or lua-unsafe characters.
-- Image name in assets/ must match the seal_id, but lowercase and adding _seal at the end. 
function add_seal(seal_id, label, desc)
    -- Prepare the data contents, add to the pools.
    local loc_id = string.lower(seal_id) .. "_seal"
    local data = {}
    data.set = 'Seal'
    data.discovered = false
    data.key = seal_id
    data.order = #G.P_CENTER_POOLS.Seal + 1
    G.P_SEALS[seal_id] = data
    table.insert(G.P_CENTER_POOLS['Seal'], data)

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

-- Debug tools for table data if you need it.
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