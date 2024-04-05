local logging = require("logging")
local logger = logging.getLogger("orange_seals")
local seal = require("seal")

local function consumeableEffect(card)
    if card.ability.name == "Gleam" then
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
    if card.ability.name == "Gleam" then
        if card.ability.consumeable.mod_num >= #G.hand.highlighted and #G.hand.highlighted >=
            (card.ability.consumeable.min_highlighted or 1) then
            return true
        end
    end
    return false
end

local function sealEffect(self, context)
    if context.discard then
        if self.seal == "Orange" and #G.hand.cards - 1 > 0 then
            local chosen_card = pseudorandom_element(G.hand.cards, pseudoseed('random_select'))
            if chosen_card == self then
                while chosen_card == self do
                    chosen_card = pseudorandom_element(G.hand.cards, pseudoseed('random_select'))
                end
            end
            local enhance_type = pseudorandom_element(G.P_CENTER_POOLS["Enhanced"], pseudoseed('enhcard'))
            chosen_card:set_ability(G.P_CENTERS[enhance_type.key], nil, true)
            card_eval_status_text(chosen_card, 'extra', nil, nil, nil, {
                message = "Enhanced!",
                colour = G.C.Grey
            })
        end
    end
end

local function on_enable()
    logger:info("Enabling orange seals.")
    seal.registerSeal({
        mod_id = "orange_seals",
        id = "Orange",
        label = "Orange Seal",
        color = "orange",
        description = {"Randomly {C:attention}enhances{} 1 card", "other than self", "when {C:attention}discarded{}",
                       "{C:inactive}(Can overwrite enhancements)"},
        effect = sealEffect,
        timing = "onDiscard"
    })
    
end

local function on_disable()
    seal.unregisterSeal("Orange")
end

local function on_key_pressed(key)
    if key == "o" then
        if #G.hand.highlighted == 1 then
            G.hand.highlighted[1]:set_seal("Orange")
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
