local logging = require("logging")
local logger = logging.getLogger("double_seals")
local seal = require("seal")
local balamod = require("balamod")

local function consumeableEffect(card)
    if card.ability.name == "Blur" then
        local allowed_list = {'Purple', 'Blue', 'Gold', 'Orange', 'Silver', 'Red'}
        local conv_card = G.hand.highlighted[1]
        local seal = nil
        local doubleable = false
        sendDebugMessage(allowed_list[3])
        for i = 1, #allowed_list do
            if conv_card.seal == allowed_list[i] then
                doubleable = true
            end
        end
        sendDebugMessage(doubleable)
        if conv_card.seal and doubleable then
            seal = 'Double' .. conv_card.seal
        else
            while seal == nil do
                local seal_type = pseudorandom(pseudoseed('blurseal' .. G.GAME.round_resets.ante), 1,
                    #G.P_CENTER_POOLS['Seal'])
                for k, v in pairs(G.P_SEALS) do
                    if v.order == seal_type then
                        seal = k
                    end
                end
                if string.sub(seal, 1, 6) == 'Double' then
                    seal = nil
                end
            end
        end
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
                conv_card:set_seal(seal, nil, true)
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
    if card.ability.name == "Blur" then
        if card.ability.consumeable.mod_num >= #G.hand.highlighted and #G.hand.highlighted >=
            (card.ability.consumeable.min_highlighted or 1) then
            return true
        end
    end
    return false
end

local function sealEffectGold(self)
    local ret = 0
    if self.seal == 'DoubleGold' then
        ret = ret + 6
    end
    return ret
end

local function sealEffectRed(self, context)
    if context.repetition then
        if self.seal == 'DoubleRed' then
            return {
                message = localize('k_again_ex'),
                repetitions = 2,
                card = self
            }
        end
    end
end

local function sealEffectPurple(self, context)
    if context.discard then
        if self.seal == 'DoublePurple' and #G.consumeables.cards + G.GAME.consumeable_buffer <
            G.consumeables.config.card_limit then
            for i = 1, math.min(2, G.consumeables.config.card_limit - #G.consumeables.cards) do
                G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
                if #G.consumeables.cards + G.GAME.consumeable_buffer > G.consumeables.config.card_limit then
                    break
                end
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.0,
                    func = (function()
                        local card = create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'pplsl')
                        card:add_to_deck()
                        G.consumeables:emplace(card)
                        G.GAME.consumeable_buffer = 0
                        return true
                    end)
                }))
            end
            card_eval_status_text(self, 'extra', nil, nil, nil, {
                message = "+2 Tarot",
                colour = G.C.PURPLE
            })
        end
    end
end

local function sealEffectOrange(self, context)
    if context.discard then
        if self.seal == 'DoubleOrange' then
            local updated_card
            for i = 1, math.min(2, #G.hand.cards - 1) do
                local chosen_card = pseudorandom_element(G.hand.cards, pseudoseed('random_select'))
                if (chosen_card == self or chosen_card == updated_card) and #G.hand.cards > 3 then
                    while chosen_card == self or chosen_card == updated_card do
                        chosen_card = pseudorandom_element(G.hand.cards, pseudoseed('random_select'))
                    end
                elseif chosen_card == self and #G.hand.card > 2 then
                    while chosen_card == self do
                        chosen_card = pseudorandom_element(G.hand.cards, pseudoseed('random_select'))
                    end
                end
                local enhance_type = pseudorandom_element(G.P_CENTER_POOLS["Enhanced"], pseudoseed('enhcard'))
                chosen_card:set_ability(G.P_CENTERS[enhance_type.key], nil, true)
                updated_card = chosen_card
                card_eval_status_text(chosen_card, 'extra', nil, nil, nil, {
                    message = "Enhanced!",
                    colour = G.C.Grey
                })
            end
        end
    end
end

local function sealEffectBlue(self, context)
    local ret = {}
    if self.seal == 'DoubleBlue' and #G.consumeables.cards + G.GAME.consumeable_buffer <
        G.consumeables.config.card_limit then
        local card_type = 'Planet'
        for i = 1, math.min(2, G.consumeables.config.card_limit - #G.consumeables.cards) do
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
            if #G.consumeables.cards + G.GAME.consumeable_buffer > G.consumeables.config.card_limit then
                break
            end
            G.E_MANAGER:add_event(Event({
                trigger = 'before',
                delay = 0.0,
                func = (function()
                    local card = create_card(card_type, G.consumeables, nil, nil, nil, nil, nil, 'blusl')
                    card:add_to_deck()
                    G.consumeables:emplace(card)
                    G.GAME.consumeable_buffer = 0
                    return true
                end)
            }))
        end
        card_eval_status_text(self, 'extra', nil, nil, nil, {
            message = "+2 Planet",
            colour = G.C.SECONDARY_SET.Planet
        })
        ret.effect = true
    end
end

local function sealEffectSilver(self, context)
    local ret = {}
    if self.seal == 'DoubleSilver' and #G.consumeables.cards + G.GAME.consumeable_buffer <
        G.consumeables.config.card_limit then
        local card_type = 'Spectral'
        for i = 1, math.min(2, G.consumeables.config.card_limit - #G.consumeables.cards) do
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
            if #G.consumeables.cards + G.GAME.consumeable_buffer > G.consumeables.config.card_limit then
                break
            end
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
        end
        card_eval_status_text(self, 'extra', nil, nil, nil, {
            message = "+2 Spectral",
            colour = G.C.SECONDARY_SET.Spectral
        })
        ret.effect = true
    end
end

local function on_enable()
    logger:info("Enabling double seals.")
    seal.registerSeal({
        mod_id = "double_seals",
        id = "DoubleGold",
        label = "Double Gold Seal",
        color = "gold",
        shader = "voucher",
        description = {"Earn {C:money}$6{} when this", "card is played", "and scores"},
        effect = sealEffectGold,
        timing = "onDollars"
    })
    seal.registerSeal({
        mod_id = "double_seals",
        id = "DoubleBlue",
        label = "Double Blue Seal",
        color = "blue",
        description = {"Creates 2 {C:planet}Planet{} cards", "if this card is {C:attention}held{} in",
        "hand at end of round", "{C:inactive}(Must have room)"},
        effect = sealEffectBlue,
        timing = "onHold"
    })
    seal.registerSeal({
        mod_id = "double_seals",
        id = "DoubleRed",
        label = "Double Red Seal",
        color = "red",
        description = {"Retrigger this", "card {C:attention}2{} times"},
        effect = sealEffectRed,
        timing = "onRepetition"
    })
    seal.registerSeal({
        mod_id = "double_seals",
        id = "DoublePurple",
        label = "Double Purple Seal",
        color = "purple",
        description = {"Creates 2 {C:tarot}Tarot{} cards", "when {C:attention}discarded.", "{C:inactive}(Must have room)"},
        effect = sealEffectPurple,
        timing = "onDiscard"
    })
    if balamod.mods["silver_seals"] then
        seal.registerSeal({
            mod_id = "double_seals",
            id = "DoubleSilver",
            label = "Double Silver Seal",
            color = "joker_grey",
            shader = "foil",
            description = {"Creates 2 {C:spectral}Spectral{} cards", "if this card is {C:attention}held{} in",
            "hand at end of round"},
            effect = sealEffectSilver,
            timing = "onHold"
        })
    end
    if balamod.mods["orange_seals"] then
        seal.registerSeal({
            mod_id = "double_seals",
            id = "DoubleOrange",
            label = "Double Orange Seal",
            color = "orange",
            description = {"Randomly {C:attention}enhances{} 2 cards", "when {C:attention}discarded{}",
            "{C:inactive}(Can overwrite enhancements)"},
            effect = sealEffectOrange,
            timing = "onDiscard"
        })
    end
end

local function on_disable()
    seal.unregisterSeal("DoubleGold")
    seal.unregisterSeal("DoubleRed")
    seal.unregisterSeal("DoubleBlue")
    seal.unregisterSeal("DoublePurple")
    seal.unregisterSeal("DoubleOrange")
    seal.unregisterSeal("DoubleSilver")
end

local function on_key_pressed(key)
    if key == "d" then
        if #G.hand.highlighted == 1 then
            if G.hand.highlighted[1].seal then
                seal = G.hand.highlighted[1].seal
                G.hand.highlighted[1]:set_seal("Double"..seal)
            end
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
