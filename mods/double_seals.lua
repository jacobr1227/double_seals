--[[For use with the Balamod mod loader. Likely not compatible with mods by other developers that introduce new seals.
Authored March 2024, Jacob Rogers
Core functions inspired by/modified from AxUtil @ https://github.com/AxBolduc/GreenSeal/blob/main/Util.lua]] mod_id =
    "double_seals"
table.insert(mods, {
    mod_id = mod_id,
    name = "Double Seals",
    author = "jacobr1227",
    version = "v0.8",
    description = {"Adds new Double versions of the 4 base game seals\n as well as all my other seal mods."},
    enabled = true,
    on_enable = function()
        add_seal("DoubleRed", "Double Red Seal", {
            name = "Double Red Seal",
            text = {"Retrigger this", "card {C:attention}2{} times"}
        })
        add_seal("DoubleGold", "Double Gold Seal", {
            name = "Double Gold Seal",
            text = {"Earn {C:money}$6{} when this", "card is played", "and scores"}
        })
        add_seal("DoubleBlue", "Double Blue Seal", {
            name = "Double Blue Seal",
            text = {"Creates 2 {C:planet}Planet{} cards", "if this card is {C:attention}held{} in",
                    "hand at end of round", "{C:inactive}(Must have room)"}
        })
        add_seal("DoublePurple", "Double Purple Seal", {
            name = "Double Purple Seal",
            text = {"Creates 2 {C:tarot}Tarot{} cards", "when {C:attention}discarded.", "{C:inactive}(Must have room)"}
        })
        if mods["Orange Seals"] then
            sendDebugMessage("Found orange seals!")
            add_seal("DoubleOrange", "Double Orange Seal", {
                name = "Double Orange Seal",
                text = {"Randomly {C:attention}enhances{} 2 cards", "when {C:attention}discarded{}",
                        "{C:inactive}(Can overwrite enhancements)"}
            })
        end
        if mods["Silver Seals"] then
            sendDebugMessage("Found silver seals!")
            add_seal("DoubleSilver", "Double Silver Seal", {
                name = "Double Silver Seal",
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
                    --Enhance two different cards in hand, randomly.
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
        local to_replace = "if p_dollars > 0 then"
        local replacement = [[if card.seal == 'DoubleGold' then
                        p_dollars = p_dollars + 6
                        end
                        if p_dollars > 0 then]]
        local file_name = "functions/common_events.lua"
        local fun_name = "eval_card"
        inject(file_name, fun_name, to_replace, replacement)

        -- Double Gold shader [[Move to API??]]
        local replacement = [[if self.seal then
                    if self.seal == 'DoubleGold' then
                        G.shared_seals[self.seal].role.draw_major = self
                        G.shared_seals[self.seal]:draw_shader('dissolve', nil, nil, nil, self.children.center)
                        G.shared_seals[self.seal]:draw_shader('voucher', nil, self.ARGS.send_to_shader, nil, self.children.center) 
                    end
                end]]
        local fun_name = "Card:draw"
        local file_name = "card.lua"
        injectTail(file_name, fun_name, replacement)

        -- Color additions for UI badges [[Move to API?]]
        local to_replace = "purple_seal = G.C.PURPLE,"
        local replacement = [[purple_seal = G.C.PURPLE,
            doublered_seal = G.C.RED,
            doublegold_seal = G.C.GOLD,
            doubleblue_seal = G.C.BLUE,
            doublepurple_seal = G.C.PURPLE,
            doubleorange_seal = G.C.ORANGE,
            doublesilver_seal = G.C.GREY,]]
        local file_name = "functions/UI_definitions.lua"
        local fun_name = "get_badge_colour"
        inject(file_name, fun_name, to_replace, replacement)

        -- Color additions for localization items [[Move to API??]]
        local to_replace = [[G.ARGS.LOC_COLOURS = G.ARGS.LOC_COLOURS or {
            red = G.C.RED,]]
        local replacement = [[G.ARGS.LOC_COLOURS = G.ARGS.LOC_COLOURS or {
            red = G.C.RED,
            doublered = G.C.RED,
            doublegold = G.C.GOLD,
            doubleblue = G.C.BLUE,
            doublepurple = G.C.PURPLE,
            doubleorange = G.C.ORANGE,
            doublesilver = G.C.GREY,]]
        local file_name = "functions/misc_functions.lua"
        local fun_name = "loc_colour"
        inject(file_name, fun_name, to_replace, replacement)

        -- Card UI updater for badges [[Move to API??]]
        inject("functions/UI_definitions.lua", "create_UIBox_your_collection_seals", "card_limit = 4", "card_limit = 8")
        inject("functions/common_events.lua", "generate_card_ui", "local info_queue = {}", [[local info_queue = {}
        if first_pass and not (_c.set == 'Edition') and badges then
            for k, v in ipairs(badges) do
                if v == 'doublered_seal' then info_queue[#info_queue + 1] = {key = 'doublered_seal', set = 'Other'} end
                if v == 'doubleblue_seal' then info_queue[#info_queue + 1] = {key = 'doubleblue_seal', set = 'Other'} end
                if v == 'doublegold_seal' then info_queue[#info_queue + 1] = {key = 'doublegold_seal', set = 'Other'} end
                if v == 'doublepurple_seal' then info_queue[#info_queue + 1] = {key = 'doublepurple_seal', set = 'Other'} end
                if v == 'doublesilver_seal' then info_queue[#info_queue + 1] = {key = 'doublesilver_seal', set = 'Other'} end
                if v == 'doubleorange_seal' then info_queue[#info_queue + 1] = {key = 'doubleorange_seal', set = 'Other'} end
            end
        end
        sendDebugMessage('Hi!')]])
        -- localize{type = 'other', key = _c.key, nodes = desc_nodes, vars = specific_vars}
        -- DoubleRed example: type = 'other', key = 'doublered_seal'
        -- loc_target = name: Double Red Seal, text: (desc)

        -- Booster pack seal appearance [BUGGED!!]
        local to_replace = [[if seal_poll > 1 - 0.02*seal_rate then
            local seal_type = pseudorandom(pseudoseed('stdsealtype'..G.GAME.round_resets.ante))
            if seal_type > 0.75 then card:set_seal('Red')
            elseif seal_type > 0.5 then card:set_seal('Blue')
            elseif seal_type > 0.25 then card:set_seal('Gold')
            else card:set_seal('Purple')
            end
            end]]
        local replacement = [[if seal_poll > 1 - 0.02*seal_rate then
            local seal_type = pseudorandom(pseudoseed('stdsealtype'..G.GAME.round_resets.ante), 1, #G.P_CENTER_POOLS['Seal'])
            local sealName
            sendDebugMessage("Man you must really love boosters...")
            for k, v in pairs(G.P_SEALS) do
                if v.order == seal_type then sealName = k end
            end
            card:set_seal(sealName)]]
        local fun_name = "Card:open"
        local file_name = "card.lua"
        inject(file_name, fun_name, to_replace, replacement)

        -- Certificate Joker seal appearance [BUGGED!!]
        local to_replace = [[local seal_type = pseudorandom(pseudoseed('certsl'))
            if seal_type > 0.75 then _card:set_seal('Red', true)
            elseif seal_type > 0.5 then _card:set_seal('Blue', true)
            elseif seal_type > 0.25 then _card:set_seal('Gold', true)
            else _card:set_seal('Purple', true)]]
        local replacement = [[local seal_type = pseudorandom(pseudoseed('certsl'))
            local sealName
            sendDebugMessage("Certified!")
            for k, v in pairs(G.P_SEALS) do
                if v.order == seal_type then sealName = k end
            end
            card:set_seal(sealName)]]
        local fun_name = "Card:calculate_joker"
        inject(file_name, fun_name, to_replace, replacement)

        sendDebugMessage("Double Seals enabled!")
    end,
    on_disable = function()
        -- introduce function disablers.
    end
})
