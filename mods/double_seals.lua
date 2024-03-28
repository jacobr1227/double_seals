--[[For use with the Balamod mod loader. Likely not compatible with mods by other developers that introduce new seals.
Authored March 2024, Jacob Rogers
Core functions inspired by/modified from AxUtil @ https://github.com/AxBolduc/GreenSeal/blob/main/Util.lua]] mod_id =
    "double_seals"

if (sendDebugMessage == nil) then
    sendDebugMessage = function(_)
    end
end

table.insert(mods, {
    mod_id = mod_id,
    name = "Double Seals",
    author = "jacobr1227",
    version = "v0.85",
    description = {"Adds new Double versions of the 4 base game seals\n as well as all my other seal mods."},
    enabled = true,
    on_enable = function()
        add_seal("DoubleGold", "Double Gold Seal", "gold", "voucher", {
            text = {"Earn {C:money}$6{} when this", "card is played", "and scores"}
        })
        add_seal("DoubleRed", "Double Red Seal", "red", nil, {
            text = {"Retrigger this", "card {C:attention}2{} times"}
        })
        add_seal("DoubleBlue", "Double Blue Seal", "blue", nil, {
            text = {"Creates 2 {C:planet}Planet{} cards", "if this card is {C:attention}held{} in",
                    "hand at end of round", "{C:inactive}(Must have room)"}
        })
        add_seal("DoublePurple", "Double Purple Seal", "purple", nil, {
            name = "Double Purple Seal",
            text = {"Creates 2 {C:tarot}Tarot{} cards", "when {C:attention}discarded.", "{C:inactive}(Must have room)"}
        })
        if mods["Orange Seals"] then
            sendDebugMessage("Found orange seals!")
            add_seal("DoubleOrange", "Double Orange Seal", "orange", nil, {
                text = {"Randomly {C:attention}enhances{} 2 cards", "when {C:attention}discarded{}",
                        "{C:inactive}(Can overwrite enhancements)"}
            })
        end
        if mods["Silver Seals"] then
            sendDebugMessage("Found silver seals!")
            add_seal("DoubleSilver", "Double Silver Seal", "grey", "polychrome", {
                text = {"Creates 2 {C:spectral}Spectral{} cards", "if this card is {C:attention}held{} in",
                        "hand at end of round"}
            })
        end

        -- Double Red/Purple/Orange code
        local calculate_seal_ref = Card.calculate_seal
        function Card:calculate_seal(context)
            local fromRef = calculate_seal_ref(self, context)
            if context.repetition then
                if self.seal == 'DoubleRed' then
                    return {
                        message = localize('k_again_ex'),
                        repetitions = 2,
                        card = self
                    }
                end
            end
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
                if self.seal == 'DoubleOrange' then
                    -- Enhance two different cards in hand, randomly.
                end
            end
            return fromRef
        end

        -- Double Blue/Silver code
        local get_end_of_round_effect_ref = Card.get_end_of_round_effect
        function Card:get_end_of_round_effect(context)
            local fromRef = get_end_of_round_effect_ref(self, context)
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
                    colour = G.C.SECONDARY_SET.Planet
                })
                ret.effect = true
            end
            return fromRef
        end
        -- Double Gold function
        -- This WILL override the original get_p_dollars function.
        -- If you're experiencing bugs in other mods, swap this block out for the inject below it.
        function Card:get_p_dollars()
            local ret = 0
            if self.seal == 'DoubleGold' then
                ret = ret + 6
            end
            if self.debuff then return 0 end
            
            if self.seal == 'Gold' then
                ret = ret +  3
            end
            if self.ability.p_dollars > 0 then
                if self.ability.effect == "Lucky Card" then 
                    if pseudorandom('lucky_money') < G.GAME.probabilities.normal/15 then
                        self.lucky_trigger = true
                        ret = ret +  self.ability.p_dollars
                    end
                else 
                    ret = ret + self.ability.p_dollars
                end
            end
            if ret > 0 then 
                G.GAME.dollar_buffer = (G.GAME.dollar_buffer or 0) + ret
                G.E_MANAGER:add_event(Event({func = (function() G.GAME.dollar_buffer = 0; return true end)}))
            end
            return ret
        end
        --[=[local to_replace = "if p_dollars > 0 then"
        local replacement = [[if card.seal == 'DoubleGold' then
                        p_dollars = p_dollars + 6
                        end
                        if p_dollars > 0 then]]
        local file_name = "functions/common_events.lua"
        local fun_name = "eval_card"
        inject(file_name, fun_name, to_replace, replacement)]=]
        
        inject_overrides()
        sendDebugMessage("Double Seals enabled!")
    end,
    on_disable = function()
        remove_seals()
    end
})