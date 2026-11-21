-- AUTO-REROLL FUNCTION FOR REROLL BUTTON
RerollSurplus.collection_targets = {}
RerollSurplus.RNG_states = { prev = nil, latest = nil }

function RerollSurplus.FUNCS.auto_reroll(targets)
  -- Start the reroll sim w/ shop_jokers as the first iteration
  for _, v in pairs(G.shop_jokers.cards) do table.insert(RerollSurplus.REROLL.key_queue, v.config.center_key) end
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
  if RerollSurplus.REROLL.spend_limit_flag or RerollSurplus.REROLL.reroll_limit_flag then
    G.CONTROLLER.locks.shop_reroll = false
    return true
  end
  local b = {config = {}}
  G.FUNCS.can_reroll(b)
  if not b.config.button then
    G.CONTROLLER.locks.shop_reroll = false
    return true
  end
  if RerollSurplus.FUNCS.check_keys(targets) then
    G.CONTROLLER.locks.shop_reroll = false
    return true
  end
  G.FUNCS.reroll_shop()

  -- Empty key queue and edition flags
  RerollSurplus.REROLL.key_queue = {}
  RerollSurplus.REROLL.edition_flags = {}

  -- Increment amount spent tracker and reroll count tracker
  RerollSurplus.REROLL.spent = RerollSurplus.REROLL.spent + G.GAME.current_round.reroll_cost - 1
  RerollSurplus.REROLL.rerolls = RerollSurplus.REROLL.rerolls + 1
  -- Check for either limit flag
  if (RerollSurplus.REROLL.spent + G.GAME.current_round.reroll_cost) > (to_number(G.GAME.dollars) - RerollSurplus.config.reroll_spend_limit) then RerollSurplus.REROLL.spend_limit_flag = true end
  if RerollSurplus.REROLL.rerolls >= RerollSurplus.config.reroll_limit then RerollSurplus.REROLL.reroll_limit_flag = true end

  -- Re-call event until something stops
  RerollSurplus.defer(function()
    for _, card in pairs(G.shop_jokers.cards) do
      RerollSurplus.REROLL.key_queue[#RerollSurplus.REROLL.key_queue+1] = card.config.center_key
      if card.edition then RerollSurplus.REROLL.edition_flags[card.edition.key] = true end
    end
    if RerollSurplus.FUNCS.check_keys(targets) then
      G.CONTROLLER.locks.shop_reroll = false
      return true
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
  while not RerollSurplus.FUNCS.check_keys(targets) and not RerollSurplus.REROLL.spend_limit_flag and not RerollSurplus.REROLL.reroll_limit_flag do
    RerollSurplus.REROLL.edition_flags = {}
    RerollSurplus.REROLL.simulate_reroll()
    RerollSurplus.RNG_states.prev = RerollSurplus.RNG_states.latest
    RerollSurplus.RNG_states.latest = copy_table(G.GAME.pseudorandom)
  end
  RerollSurplus.in_reroll_sim = nil

  -- Do all the calculations with none of the actual rerolls.
  if RerollSurplus.RNG_states.prev then
    RerollSurplus.REROLL.skip_to_last()
  end
  -- Set the RNG state to one reroll from results, so we can reroll once into the correct spot
  G.GAME.used_jokers = used_jokers
  G.GAME.pseudorandom = RerollSurplus.RNG_states.prev or RNG_state
  -- Reroll
  RerollSurplus.defer(G.FUNCS.reroll_shop)
  -- Display results
  RerollSurplus.FUNCS.display_results(targets)
  -- Reset values to defaults for next time
  RerollSurplus.FUNCS.reset_rerolls()
end

function RerollSurplus.FUNCS.check_keys(targets)
  for _, key in pairs(targets) do
    if RerollSurplus.utils.contains(RerollSurplus.REROLL.key_queue, key) then
      return true
    elseif RerollSurplus.REROLL.edition_flags[''..key] then
      return true
    end
  end
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
  print("Total rerolls: " .. RerollSurplus.REROLL.rerolls)
end

function RerollSurplus.FUNCS.reset_rerolls()
  RerollSurplus.RNG_states = { prev = nil, latest = nil }
  RerollSurplus.REROLL.rerolls = 0
  RerollSurplus.REROLL.spent = 0
  RerollSurplus.REROLL.key_queue = {}
  RerollSurplus.REROLL.edition_flags = {}
  RerollSurplus.REROLL.tag_cache = {}
  RerollSurplus.REROLL.tag_queue = {}
  RerollSurplus.reroll_cost = nil
  RerollSurplus.reroll_cost_inc = nil
  RerollSurplus.free_rerolls = nil
  RerollSurplus.REROLL.spend_limit_flag = nil
  RerollSurplus.REROLL.reroll_limit_flag = nil
end

