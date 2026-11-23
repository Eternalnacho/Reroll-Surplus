-- SHOP REROLL SIMULATION FUNCTIONS
local Reroller = RerollSurplus.REROLL
local util = RerollSurplus.utils

function Reroller.simulate_reroll()
  -- Tracking reroll cost + total money spent
  Reroller.reroll_cost = Reroller.reroll_cost or G.GAME.current_round.reroll_cost
  Reroller.spent = Reroller.spent + Reroller.reroll_cost

  -- Accounting for free rerolls in spending calculations
  Reroller.free_rerolls = Reroller.free_rerolls or G.GAME.current_round.free_rerolls
  Reroller.calculate_reroll_cost(Reroller.free_rerolls > 0)
  Reroller.free_rerolls = math.max(Reroller.free_rerolls - 1, 0)

  -- Clearing the "shop jokers" in simulation
  for i = #Reroller.key_queue, 1, -1 do
    if G.GAME.used_jokers[Reroller.key_queue[i]] then G.GAME.used_jokers[Reroller.key_queue[i]] = nil end
    table.remove(Reroller.key_queue, i)
  end

  -- Get next set of shop jokers
  for _ = 1, G.GAME.shop.joker_max do
    Reroller.get_next_shop_key()
  end

  -- Increment reroll count
  Reroller.rerolls = Reroller.rerolls + 1
  
  if not RerollSurplus.FUNCS.check_limits(1) and next(G.jokers.cards) then
    RerollSurplus.skip_anims = true
    Reroller.in_reroll_sim_context = true
    SMODS.calculate_context({reroll_shop = true, cost = Reroller.reroll_cost})
    Reroller.in_reroll_sim_context = nil
    RerollSurplus.skip_anims = nil
  end
end

function Reroller.calculate_reroll_cost(skip_increase)
  Reroller.reroll_cost_inc = Reroller.reroll_cost_inc or 0
  if not skip_increase then Reroller.reroll_cost_inc = Reroller.reroll_cost_inc + 1 end
  Reroller.reroll_cost = G.GAME.current_round.reroll_cost + Reroller.reroll_cost_inc
end

function Reroller.get_next_shop_key()
  local card = create_card_for_shop(G.shop_jokers)
  -- Get relevant info from the card
  local key = card.config.center_key
  local edition = card.edition and card.edition.key
  -- Remove the card
  card.states.visible = nil
  card:remove()
  -- if card.config.center.consumeable then RerollSurplus.defer(function() card:remove() end, { blockable = true })
  -- else card:remove() end
  -- Keep card info stored in relevant places
  Reroller.key_queue[#Reroller.key_queue+1] = key
  Reroller.edition_flags[(edition or 'null')] = true
  G.GAME.used_jokers[key] = true
end

function Reroller.skip_to_last()
  for _, tag in pairs(Reroller.tag_cache) do
    if util.contains(Reroller.tag_queue, tag) then tag.triggered = false
    else tag:remove() end
  end

  if Reroller.rerolls > 0 then
    inc_career_stat('c_shop_dollars_spent', Reroller.spent - Reroller.reroll_cost)
    inc_career_stat('c_shop_rerolls', Reroller.rerolls - 1)
    ease_dollars(-(Reroller.spent - Reroller.reroll_cost), true)
  end

  G.GAME.current_round.reroll_cost = G.GAME.current_round.reroll_cost + Reroller.rerolls - 1
  G.GAME.current_round.reroll_cost_increase = G.GAME.current_round.reroll_cost_increase + Reroller.reroll_cost_inc - 1
  G.GAME.round_scores.times_rerolled.amt = G.GAME.round_scores.times_rerolled.amt + Reroller.rerolls - 1
end