--[[For use with the Balamod mod loader. Likely not compatible with mods by other developers that introduce new seals.
Authored March 2024, Jacob Rogers]]
local mod_id = "silver_seals"

if (sendDebugMessage == nil) then
    sendDebugMessage = function(_)
    end
end

table.insert(mods, {
    mod_id = mod_id,
    name = "Silver Seals",
    author = "jacobr1227",
    version = "v1.0",
    description = {"Adds new Silver seal\n When held in hand at end of round,\n creates 1 spectral card."},
    enabled = true,
    on_enable = function()
        add_seal("Silver", "Silver Seal", "grey", "foil", {
            text = {"Creates 1 {C:spectral}Spectral{} card", "if this card is {C:attention}held{} in",
                        "hand at end of round"}
        })
        local get_end_of_round_effect_ref = Card.get_end_of_round_effect
        function Card:get_end_of_round_effect(context)
            local fromRef = get_end_of_round_effect_ref(self, context)
            local ret = {}
            if self.seal == 'Silver' and #G.consumeables.cards + G.GAME.consumeable_buffer <
                G.consumeables.config.card_limit then
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
            return fromRef
        end
        inject_overrides()
        sendDebugMessage("Silver Seals enabled.")
    end,
    on_disable = function()
        remove_seals()
    end
})