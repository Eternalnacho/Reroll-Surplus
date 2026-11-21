-- REROLL SIMULATOR FUNCTION HOOKS


-- CARD CREATION FUNCTIONS

RerollSurplus.Hook("around", SMODS, 'create_card', function(orig, t, ...)
  if RerollSurplus.in_reroll_sim and RerollSurplus.from_tag then
    RerollSurplus.REROLL.tag_args = copy_table(t)
    RerollSurplus.REROLL.from_scc = true
  end
  local ret = orig(t, ...)
  RerollSurplus.REROLL.from_scc, RerollSurplus.from_tag = nil, nil
  return ret
end)

RerollSurplus.Hook("around", _G, 'create_card', function(orig, _type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append, ...)
  if RerollSurplus.in_reroll_sim and not RerollSurplus.REROLL.from_scc then
    RerollSurplus.REROLL.tag_args = {
      set = _type,
      legendary = legendary,
      rarity = _rarity,
      key = forced_key,
      key_append = key_append
    }
  end
  local ret = orig(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append, ...)
  return ret
end)

-- TAG FUNCTIONS

RerollSurplus.Hook("around", Tag, 'yep', function(orig, self, ...)
  if RerollSurplus.in_reroll_sim then
    self.triggered = false
    return
  else orig(self, ...) end
end)

RerollSurplus.Hook("around", Tag, 'nope', function(orig, self, ...)
  if RerollSurplus.in_reroll_sim then
    self.triggered = false
    return
  else orig(self, ...) end
end)

RerollSurplus.Hook("around", Tag, 'apply_to_run', function(orig, self, ...)
  if RerollSurplus.in_reroll_sim then
    self.triggered = false
    return
  else orig(self, ...) end
end)

-- CALCULATION FUNCTIONS

RerollSurplus.Hook("around", _G, 'card_eval_status_text', function(orig, ...)
  if not RerollSurplus.skip_anims then orig(...) end
end)

RerollSurplus.Hook("around", _G, 'juice_card', function(orig, ...)
  if not RerollSurplus.skip_anims then orig(...) end
end)

RerollSurplus.Hook("around", Card, 'juice_up', function(orig, ...)
  if not RerollSurplus.skip_anims then orig(...) end
end)