-- SHOP REROLL SIMULATION FUNCTIONS
RerollSurplus.REROLL = {
  key_queue = {},
  tag_cache = {},
  tag_queue = {},
  tag_args = {},
  edition_flags = {},
  rerolls = 0,
  spent = 0,
  spend_limit_flag = nil,
  reroll_limit_flag = nil,
  reroll_limit_price = RerollSurplus.config.reroll_limit,
  reroll_safety_threshold = RerollSurplus.config.reroll_safety_threshold,
}

function RerollSurplus.REROLL.simulate_reroll()
  RerollSurplus.reroll_cost = RerollSurplus.reroll_cost or G.GAME.current_round.reroll_cost
  if (RerollSurplus.REROLL.spent + RerollSurplus.reroll_cost) > (to_number(G.GAME.dollars) - RerollSurplus.config.reroll_safety_threshold) then
    RerollSurplus.REROLL.spend_limit_flag = true
    return
  end
  -- Tracking total money spent
  RerollSurplus.REROLL.spent = RerollSurplus.REROLL.spent + RerollSurplus.reroll_cost
  -- Accounting for free rerolls in spending calculations
  RerollSurplus.free_rerolls = RerollSurplus.free_rerolls or G.GAME.current_round.free_rerolls
  local final_free = RerollSurplus.free_rerolls > 0
  RerollSurplus.free_rerolls = math.max(RerollSurplus.free_rerolls - 1, 0)
  RerollSurplus.REROLL.calculate_reroll_cost(final_free)
  -- Clearing the "shop jokers" in simulation
  for i = #RerollSurplus.REROLL.key_queue, 1, -1 do
    if G.GAME.used_jokers[RerollSurplus.REROLL.key_queue[i]] then G.GAME.used_jokers[RerollSurplus.REROLL.key_queue[i]] = nil end
    table.remove(RerollSurplus.REROLL.key_queue, i)
  end
  RerollSurplus.REROLL.tag_queue = {}
  -- Get next set of shop jokers
  for _ = 1, G.GAME.shop.joker_max do
    RerollSurplus.REROLL.get_next_shop_key()
  end
  -- Increment reroll count
  RerollSurplus.REROLL.rerolls = RerollSurplus.REROLL.rerolls + 1
  if RerollSurplus.REROLL.rerolls >= RerollSurplus.config.reroll_limit then RerollSurplus.REROLL.reroll_limit_flag = true end
end

function RerollSurplus.REROLL.calculate_reroll_cost(skip_increase)
  RerollSurplus.reroll_cost_inc = RerollSurplus.reroll_cost_inc or 0
  if not skip_increase then RerollSurplus.reroll_cost_inc = RerollSurplus.reroll_cost_inc + 1 end
  RerollSurplus.reroll_cost = G.GAME.current_round.reroll_cost + RerollSurplus.reroll_cost_inc
end

function RerollSurplus.REROLL.get_next_shop_key()
  -- Checking tags for store modifiers
  local k_shop_tag, k_tag_type = RerollSurplus.REROLL.get_next_shop_tag('create')
  local e_shop_tag, e_tag_type = RerollSurplus.REROLL.get_next_shop_tag('modify')
  local args = RerollSurplus.REROLL.check_rates()
  -- Check if tag changes rates / keys
  if k_shop_tag then
    RerollSurplus.REROLL.calculate_shop_tag(k_shop_tag, k_tag_type, args)
    table.insert(RerollSurplus.REROLL.tag_cache, k_shop_tag)
    table.insert(RerollSurplus.REROLL.tag_queue, k_shop_tag)
  end
  if e_shop_tag then
    RerollSurplus.REROLL.calculate_shop_tag(e_shop_tag, e_tag_type, args)
    table.insert(RerollSurplus.REROLL.tag_cache, e_shop_tag)
    table.insert(RerollSurplus.REROLL.tag_queue, k_shop_tag)
  end
  -- if there's a forced key we know what joker will appear
  if args.key then
    RerollSurplus.REROLL.key_queue[#RerollSurplus.REROLL.key_queue+1] = args.key
  -- *now* we get the pool and so on
  else
    local _pool, _pool_key = get_current_pool(args.set, args.rarity, args.legendary, args.key_append)
    local center_key = pseudorandom_element(_pool, pseudoseed(_pool_key))
    local it = 1
    while center_key == 'UNAVAILABLE' do
        it = it + 1
        center_key = pseudorandom_element(_pool, pseudoseed(_pool_key..'_resample'..it))
    end
    RerollSurplus.REROLL.key_queue[#RerollSurplus.REROLL.key_queue+1] = center_key
  end
  -- counting editions
  if args.edition then
    RerollSurplus.REROLL.edition_flags[args.edition] = true
  elseif args.set == 'Joker' then
    local edition = poll_edition('edi'..(args.key_append or '')..G.GAME.round_resets.ante)
    if edition then RerollSurplus.REROLL.edition_flags[edition] = true end
  end
  G.GAME.used_jokers[RerollSurplus.REROLL.key_queue[#RerollSurplus.REROLL.key_queue]] = true
end

function RerollSurplus.REROLL.get_next_shop_tag(_type)
  for _, v in ipairs(G.GAME.tags) do
    if v.config.type == 'store_joker_'.._type and not RerollSurplus.utils.contains(RerollSurplus.REROLL.tag_cache, v) then
      return v, v.config.type
    end
  end
end

function RerollSurplus.REROLL.calculate_shop_tag(tag, tag_type, args)
  RerollSurplus.from_tag = true
  local flags = SMODS.calculate_context({prevent_tag_trigger = tag, other_context = {type = tag_type, area = G.shop_jokers}})
  if flags and flags.prevent_trigger or RerollSurplus.utils.contains(RerollSurplus.REROLL.tag_cache, tag) then return end
  if tag_type == 'store_joker_create' then
    -- There are only two vanilla store_joker_create tags
    if tag.name == 'Rare Tag' then
      args.key_append = 'rta'
      args.rarity = 1
      args.set = 'Joker'
    elseif tag.name == 'Uncommon Tag' then
      args.key_append = 'uta'
      args.rarity = 0.9
      args.set = 'Joker'
    -- Modded store_joker_create tags
    else
      local card = tag:apply_to_run({type = 'store_joker_create', area = G.shop_jokers})
      for k, v in pairs(RerollSurplus.REROLL.tag_args) do
        args[k] = v
      end
      if card then card:remove() end
    end
  else
    local tag_center = G.P_TAGS[tag.key]
    if tag_center and tag_center.config.edition and args.set == 'Joker' then
      RerollSurplus.REROLL.edition_flags['e_'..tag_center.config.edition] = true
    end
  end
  RerollSurplus.from_tag = nil
end

function RerollSurplus.REROLL.get_card_type_rates()
  G.GAME.spectral_rate = G.GAME.spectral_rate or 0
  -- need to preserve order to leave RNG unchanged
  local rates = {
    {type = 'Joker', val = G.GAME.joker_rate},
    {type = 'Tarot', val = G.GAME.tarot_rate},
    {type = 'Planet', val = G.GAME.planet_rate},
    {type = (G.GAME.used_vouchers["v_illusion"] and pseudorandom(pseudoseed('illusion')) > 0.6) and 'Enhanced' or 'Base', val = G.GAME.playing_card_rate},
    {type = 'Spectral', val = G.GAME.spectral_rate},
  }
  for _, v in ipairs(SMODS.ConsumableType.ctype_buffer) do
      if not (v == 'Tarot' or v == 'Planet' or v == 'Spectral') then
          table.insert(rates, { type = v, val = G.GAME[v:lower()..'_rate'] })
      end
  end
  return rates
end

function RerollSurplus.REROLL.check_rates()
  local rates = RerollSurplus.REROLL.get_card_type_rates()
  local check_rate = 0
  local total_rate = G.GAME.joker_rate + G.GAME.playing_card_rate
  for _, v in ipairs(SMODS.ConsumableType.ctype_buffer) do
      total_rate = total_rate + G.GAME[v:lower()..'_rate']
  end
  local polled_rate = pseudorandom(pseudoseed('cdt'..G.GAME.round_resets.ante)) * total_rate

  for _, v in ipairs(rates) do
    if polled_rate > check_rate and polled_rate <= check_rate + v.val then
      local args = {set = v.type, area = G.shop_jokers, key_append = 'sho'}
      local flags
      -- CHECK IF CALCULATING CONTEXTS CREATE_SHOP_CARD AND MODIFY_SHOP_CARD WILL SUCK
      flags = SMODS.calculate_context({create_shop_card = true, set = v.type})
      args = SMODS.merge_defaults(flags and flags.shop_create_flags or {}, args) or args
      return args
    end
    check_rate = check_rate + v.val
  end
end

function Tag:surplus_remove_tag()
  RerollSurplus.defer(function() self.HUD_tag.states.visible = false end)
  RerollSurplus.defer(function() self:remove() end, {delay = 0.1})
end

function RerollSurplus.REROLL.skip_to_last()
  for _, v in pairs(RerollSurplus.REROLL.tag_cache) do
    if not RerollSurplus.utils.contains(RerollSurplus.REROLL.tag_queue, v) then v:surplus_remove_tag() end
  end

  if RerollSurplus.REROLL.rerolls > 0 then
    inc_career_stat('c_shop_dollars_spent', RerollSurplus.REROLL.spent - RerollSurplus.reroll_cost)
    inc_career_stat('c_shop_rerolls', RerollSurplus.REROLL.rerolls - 1)
    ease_dollars(-(RerollSurplus.REROLL.spent - RerollSurplus.reroll_cost))
  end

  RerollSurplus.skip_anims = true
  if next(G.jokers.cards) then
    for i = 1, RerollSurplus.REROLL.rerolls - 1 do
      SMODS.calculate_context({reroll_shop = true, cost = G.GAME.current_round.reroll_cost + (i-1)})
    end
  end
  RerollSurplus.skip_anims = nil

  G.GAME.current_round.reroll_cost = G.GAME.current_round.reroll_cost + RerollSurplus.REROLL.rerolls - 1
  G.GAME.current_round.reroll_cost_increase = G.GAME.current_round.reroll_cost_increase + RerollSurplus.reroll_cost_inc - 1
  G.GAME.round_scores.times_rerolled.amt = G.GAME.round_scores.times_rerolled.amt + RerollSurplus.REROLL.rerolls - 1
end