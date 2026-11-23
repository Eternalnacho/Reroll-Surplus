-- REROLL SIMULATOR FUNCTION HOOKS

-- CARD CREATION FUNCTIONS

RerollSurplus.Hook("around", SMODS, 'create_card', function(SMODS_create_card, t, ...)
  if RerollSurplus.in_reroll_sim then t.silent = true end
  local ret = SMODS_create_card(t, ...)
  if RerollSurplus.REROLL.in_reroll_sim_context and ret then
    RerollSurplus.REROLL.key_queue[#RerollSurplus.REROLL.key_queue+1] = ret.config.center_key
    ret.states.visible = false
    ret:remove()
  end
  return ret
end)

-- TAG FUNCTIONS

RerollSurplus.Hook("around", Tag, 'yep', function(Tag_yep, self, message, _colour, func, ...)
  if RerollSurplus.in_reroll_sim then
    func()
    RerollSurplus.REROLL.tag_queue[#RerollSurplus.REROLL.tag_queue + 1] = self
    RerollSurplus.REROLL.tag_cache[#RerollSurplus.REROLL.tag_cache + 1] = self
  else
    Tag_yep(self, message, _colour, func, ...)
  end
end)

RerollSurplus.Hook("around", Tag, 'nope', function(Tag_nope, self, ...)
  if RerollSurplus.in_reroll_sim then
    RerollSurplus.REROLL.tag_queue[#RerollSurplus.REROLL.tag_queue + 1] = self
    RerollSurplus.REROLL.tag_cache[#RerollSurplus.REROLL.tag_cache + 1] = self
  else
    Tag_nope(self, ...)
  end
end)

-- EVENT QUEUE FUNCTIONS 

RerollSurplus.Hook("around", EventManager, "add_event", function(EventManager_add_event, self, event, queue, ...)
  if RerollSurplus.in_reroll_sim then
    queue = 'surplus_reroll_sim'
  end
  return EventManager_add_event(self, event, queue, ...)
end)