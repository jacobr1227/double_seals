local logging = require("logging")
local logger = logging.getLogger("silver_seals")
local seal = require("seal")

local function consumeableEffect(card)
    if card.ability.name == "Mystic" then
        local conv_card = G.hand.highlighted[1]
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                card:juice_up(0.3, 0.5)
                card_eval_status_text(conv_card, 'extra', nil, nil, nil, {
                    message = "Sealed!"
                })
                return true
            end
        }))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.2,
            func = function()
                conv_card:set_seal(card.ability.extra, nil, true)
                return true
            end
        }))
        delay(0.6)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.2,
            func = function()
                G.hand:unhighlight_all();
                return true
            end
        }))
    end
end

local function consumeableCondition(card)
    if card.ability.name == "Mystic" then
        if card.ability.consumeable.mod_num >= #G.hand.highlighted and #G.hand.highlighted >=
            (card.ability.consumeable.min_highlighted or 1) then
            return true
        end
    end
    return false
end

local function sealEffect(self, context)
    local ret = {}
    if self.seal == 'Silver' and #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
        local card_type = 'Spectral'
        G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
        G.E_MANAGER:add_event(Event({
            trigger = 'before',
            delay = 0.0,
            func = (function()
                local card = create_card(card_type, G.consumeables, nil, nil, nil, nil, nil, 'silsl')
                card:add_to_deck()
                G.consumeables:emplace(card)
                G.GAME.consumeable_buffer = 0
                return true
            end)
        }))
        card_eval_status_text(self, 'extra', nil, nil, nil, {
            message = localize('k_plus_spectral'),
            colour = G.C.SECONDARY_SET.Spectral
        })
        ret.effect = true
    end
end

local function on_enable()
    logger:info("Enabling silver seals.")
    seal.registerSeal({
        mod_id = "silver_seals",
        id = "Silver",
        label = "Silver Seal",
        color = "joker_grey",
        shader = "foil",
        description = {"Creates 1 {C:spectral}Spectral{} card", "if this card is {C:attention}held{} in",
                       "hand at end of round"},
        effect = sealEffect,
        timing = "onHold"
    })
end

local function on_disable()
    seal.unregisterSeal("Silver")
end

local function on_key_pressed(key)
    if key == "s" then
        if #G.hand.highlighted == 1 then
            G.hand.highlighted[1]:set_seal("Silver")
        end
    end
end

local function on_error(message)
    logger:error(message)
end

return {
    on_enable = on_enable,
    on_disable = on_disable,
    on_key_pressed = on_key_pressed,
    on_error = on_error
}
