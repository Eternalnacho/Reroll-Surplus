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
  RNG_states = { prev = nil, latest = nil },
  result = {}
}
local Reroller = RerollSurplus.REROLL

function RerollSurplus.FUNCS.start_auto_reroll(targets)
  -- Start the reroll sim w/ shop_jokers as the first iteration
  for _, v in pairs(G.shop_jokers.cards) do table.insert(Reroller.key_queue, v.config.center_key) end
  -- Use predictive rerolling for skipping animations
  if RerollSurplus.config.skip_reroll_anims then
    RerollSurplus.FUNCS.reroll_anim_skip(targets)
  -- Use a "normal" auto-reroll otherwise
  else
    Reroller.in_search = true
    RerollSurplus.FUNCS.auto_reroll_event(targets)
  end
end

function RerollSurplus.FUNCS.auto_reroll_event(targets)
  Reroller.reroll_cost = G.GAME.current_round.reroll_cost
  -- Fake "reroll button"
  local reroll_check = {config = {}}
  G.FUNCS.can_reroll(reroll_check)
  -- Check interrupts
  if Reroller.auto_roll_stopped or RerollSurplus.FUNCS.check_keys(targets) or RerollSurplus.FUNCS.check_limits()
      or not reroll_check.config.button then
    G.CONTROLLER.locks.shop_reroll = false
    -- Display results
    RerollSurplus.FUNCS.display_results()
    -- Reset values to defaults for next time
    RerollSurplus.FUNCS.reset_rerolls()
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
    RerollSurplus.FUNCS.auto_reroll_event(RerollSurplus.collection_targets)
  end, {blocking = false, blockable = true})
  return true
end

function RerollSurplus.FUNCS.reroll_anim_skip(targets)
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
  G.E_MANAGER:clear_queue('surplus_reroll_sim')
  -- Do all the calculations with none of the actual rerolls.
  if Reroller.RNG_states.prev then
    Reroller.skip_to_last()
  end
  -- Set the RNG state to one reroll from results, so we can reroll once into the correct spot
  G.GAME.used_jokers = used_jokers
  G.GAME.pseudorandom = Reroller.RNG_states.prev or RNG_state

  -- Reroll
  RerollSurplus.defer(G.FUNCS.reroll_shop)
  -- Display results
  RerollSurplus.defer(RerollSurplus.FUNCS.display_results)
  -- Reset values to defaults for next time
  RerollSurplus.defer(RerollSurplus.FUNCS.reset_rerolls)
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

function RerollSurplus.FUNCS.display_results()
  local targets = RerollSurplus.collection_targets
  local total_rerolls = Reroller.rerolls
  local keys_found = RerollSurplus.FUNCS.check_keys(targets)

  Reroller.result = {
    text = localize("b_Surplus_total_rerolls") .. total_rerolls,
    scale = 0.7,
    hold = 2 * G.SPEEDFACTOR,
    align = 'cm',
    offset = { x = 0, y = -2.5 }, major = G.ROOM_ATTACH,
  }
  -- Display results for posterity, and for better tracking
  if keys_found then
    RerollSurplus.defer(function()
      play_sound('holo1')
      play_sound('timpani')
    end, {delay = 0.5})
  end
  RerollSurplus.defer(function() attention_text(Reroller.result) end, { delay = 0.5 })
end

function RerollSurplus.FUNCS.reset_rerolls()
  Reroller.RNG_states = { prev = nil, latest = nil }
  Reroller.rerolls = 0
  Reroller.key_queue = {}
  Reroller.edition_flags = {}
  Reroller.tag_cache = {}
  Reroller.tag_queue = {}
  Reroller.reroll_cost = nil
  Reroller.reroll_cost_inc = nil
  Reroller.free_rerolls = nil
  Reroller.in_search = nil
  Reroller.auto_roll_stopped = nil
end

RerollSurplus.Hook('before', love, 'keypressed', function(key)
  if key == "escape" and Reroller.in_search then
    Reroller.auto_roll_stopped = true
    return true
  end
end)
