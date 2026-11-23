-- AUTO-REROLL FUNCTION FOR REROLL BUTTON
RerollSurplus.REROLL = {
  key_queue = {},
  tag_cache = {},
  tag_queue = {},
  tag_args = {},
  edition_flags = {},
  rerolls = 0,
  spent = 0,
  a_limit = RerollSurplus.config.reroll_limit,
  m_savings = RerollSurplus.config.reroll_safety_threshold,
  RNG_states = { prev = nil, latest = nil }
}
local Reroller = RerollSurplus.REROLL

function RerollSurplus.FUNCS.auto_reroll(targets)
  -- Start the reroll sim w/ shop_jokers as the first iteration
  for _, v in pairs(G.shop_jokers.cards) do table.insert(Reroller.key_queue, v.config.center_key) end
  -- Use predictive rerolling for skipping animations
  if RerollSurplus.config.skip_reroll_anims then
    RerollSurplus.FUNCS.predictive_reroll(targets)
  else
    -- Use a "normal" auto-reroll otherwise
    RerollSurplus.FUNCS.auto_roll_event(targets)
    -- Display results
    RerollSurplus.FUNCS.display_results(targets)
    -- Reset values to defaults for next time
    RerollSurplus.FUNCS.reset_rerolls()
  end
end

function RerollSurplus.FUNCS.auto_roll_event(targets)
  Reroller.reroll_cost = G.GAME.current_round.reroll_cost
  -- Fake "reroll button"
  local reroll_check = {config = {}}
  G.FUNCS.can_reroll(reroll_check)
  -- Check interrupts
  if RerollSurplus.FUNCS.check_keys(targets) or RerollSurplus.FUNCS.check_limits()
      or not reroll_check.config.button then
    G.CONTROLLER.locks.shop_reroll = false
    return true
  end

  G.FUNCS.reroll_shop()

  -- Empty key queue and edition flags
  Reroller.key_queue = {}
  Reroller.edition_flags = {}

  -- Increment reroll count tracker
  Reroller.rerolls = Reroller.rerolls + 1

  -- Re-call event until something stops
  RerollSurplus.defer(function()
    for _, card in pairs(G.shop_jokers.cards) do
      Reroller.key_queue[#Reroller.key_queue+1] = card.config.center_key
      if card.edition then Reroller.edition_flags[card.edition.key] = true end
    end
    RerollSurplus.FUNCS.auto_roll_event(RerollSurplus.collection_targets)
  end, {blocking = false, blockable = true})
  return true
end

function RerollSurplus.FUNCS.predictive_reroll(targets)
  -- Save the RNG state for later, so we can default the game state to this
  local RNG_state = copy_table(G.GAME.pseudorandom)
  local used_jokers = copy_table(G.GAME.used_jokers)

  RerollSurplus.in_reroll_sim = true
  while (not RerollSurplus.FUNCS.check_keys(targets) and not RerollSurplus.FUNCS.check_limits()) do
    Reroller.tag_queue = {}
    Reroller.edition_flags = {}
    Reroller.simulate_reroll()
    Reroller.RNG_states.prev = Reroller.RNG_states.latest
    Reroller.RNG_states.latest = copy_table(G.GAME.pseudorandom)
  end
  RerollSurplus.in_reroll_sim = nil

  -- Do all the calculations with none of the actual rerolls.
  if Reroller.RNG_states.prev then
    Reroller.skip_to_last()
  end
  -- Set the RNG state to one reroll from results, so we can reroll once into the correct spot
  G.GAME.used_jokers = used_jokers
  G.GAME.pseudorandom = Reroller.RNG_states.prev or RNG_state

  G.E_MANAGER:clear_queue('surplus_reroll_sim')
  -- Reroll
  RerollSurplus.defer(G.FUNCS.reroll_shop)
  -- Display results
  RerollSurplus.FUNCS.display_results(targets)
  -- Reset values to defaults for next time
  RerollSurplus.FUNCS.reset_rerolls()
end

function RerollSurplus.FUNCS.check_keys(targets)
  for _, key in pairs(targets) do
    if RerollSurplus.utils.contains(Reroller.key_queue, key) then
      return true
    elseif Reroller.edition_flags[''..key] then
      return true
    end
  end
end

function RerollSurplus.FUNCS.check_limits(cost_mod, count_mod)
  local reroll_cost = (Reroller.reroll_cost or G.GAME.current_round.reroll_cost) + (cost_mod or 0)
  local savings_flag = (to_number(G.GAME.dollars) - Reroller.spent - reroll_cost) < Reroller.m_savings
  local attempt_flag = Reroller.rerolls >= (Reroller.a_limit + (count_mod or 0))
  return savings_flag or attempt_flag
end

function RerollSurplus.FUNCS.display_results(targets)
  -- Display results for posterity, and for better tracking
  if not RerollSurplus.FUNCS.check_keys(targets) then print("Reached reroll limit, joker not found")
  else
    RerollSurplus.defer(function()
      play_sound('holo1')
      play_sound('timpani')
    end, {delay = 0.5})
  end
  print("Total rerolls: " .. Reroller.rerolls)
end

function RerollSurplus.FUNCS.reset_rerolls()
  RerollSurplus.REROLL.RNG_states = { prev = nil, latest = nil }
  RerollSurplus.REROLL.rerolls = 0
  RerollSurplus.REROLL.key_queue = {}
  RerollSurplus.REROLL.edition_flags = {}
  RerollSurplus.REROLL.tag_cache = {}
  RerollSurplus.REROLL.tag_queue = {}
  RerollSurplus.REROLL.reroll_cost = nil
  RerollSurplus.REROLL.reroll_cost_inc = nil
  RerollSurplus.REROLL.free_rerolls = nil
end

