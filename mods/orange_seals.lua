--[[For use with the Balamod mod loader. Likely not compatible with mods by other developers that introduce new seals.
Authored March 2024, Jacob Rogers]] 
local mod_id = "orange_seals"

if (sendDebugMessage == nil) then
    sendDebugMessage = function(_)
    end
end

table.insert(mods, {
    mod_id = mod_id,
    name = "Orange Seals",
    author = "jacobr1227",
    version = "v1.0",
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
        inject_overrides()
        sendDebugMessage("Orange Seals enabled.")
    end,
    on_disable = function()
        remove_seals()
    end
})
