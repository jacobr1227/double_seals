--[[For use with the Balamod mod loader. Likely not compatible with mods by other developers that introduce new seals.
Authored March 2024, Jacob Rogers]] 
local mod_id = "orange_seals"

if (sendDebugMessage == nil) then
    sendDebugMessage = function(_)
    end
end

local function consumeableEffect(card)
    if card.ability.name == "Gleam" then
        local conv_card = G.hand.highlighted[1]
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            play_sound('tarot1')
            card:juice_up(0.3, 0.5)
            card_eval_status_text(conv_card, 'extra', nil, nil, nil, {message="Sealed!"})
            return true end}))
        G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.2,func = function()
            conv_card:set_seal(card.ability.extra, nil, true)
            return true end }))
        delay(0.6)
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.2,func = function() G.hand:unhighlight_all(); return true end }))
    end
end

local function consumeableCondition(card)
    if card.ability.name == "Gleam" then
        if card.ability.consumeable.mod_num >= #G.hand.highlighted and #G.hand.highlighted >= (card.ability.consumeable.min_highlighted or 1) then
            return true
        end
    end
    return false
end

table.insert(mods, {
    mod_id = mod_id,
    name = "Orange Seals",
    author = "jacobr1227",
    version = "v2.0",
    description = {"Adds new Orange seal\n When discarded, enhances a random card."},
    enabled = true,
    on_enable = function()
        add_seal("Orange", "Orange Seal", "orange", nil, {
            text = {"Randomly {C:attention}enhances{} 1 card", "other than self", "when {C:attention}discarded{}",
                        "{C:inactive}(Can overwrite enhancements)"}
        })
        local calculate_seal_ref = Card.calculate_seal
        function Card:calculate_seal(context)
            local fromRef = calculate_seal_ref(self, context)
            if context.discard then
                if self.seal == "Orange" and #G.hand.cards-1 > 0 then
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
            return fromRef
        end
        local spectral, text = centerHook.addSpectral(self, "c_gleam", "Gleam", consumeableEffect,
            consumeableCondition, nil, true, 4, {
                x = 0,
                y = 0
            }, {extra = 'Orange', max_highlighted = 1}, {"Add an {C:orange}Orange Seal{}", "to {C:attention}1{} selected", "card in your hand"}, true,
            "assets", "gleam_spectral.png")
        inject_overrides()
        inject_seal_infotip("Spectral", "Gleam", "orange")
        sendDebugMessage("Orange Seals enabled.")
    end,
    on_disable = function()
        remove_seals()
    end
})
