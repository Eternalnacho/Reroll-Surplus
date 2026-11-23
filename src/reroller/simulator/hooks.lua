-- REROLL SIMULATOR FUNCTION HOOKS


-- CARD CREATION FUNCTIONS

RerollSurplus.Hook("around", SMODS, 'create_card', function(SMODS_create_card, t, ...)
  if RerollSurplus.in_reroll_sim then t.silent = true end
  local ret = SMODS_create_card(t, ...)
  if RerollSurplus.REROLL.in_reroll_sim_context and ret then
    RerollSurplus.REROLL.key_queue[#RerollSurplus.REROLL.key_queue+1] = ret.config.center_key
    ret.states.visible = false
    RerollSurplus.defer(function() ret:remove() end)
  end
  return ret
end)

-- TAG FUNCTIONS

RerollSurplus.Hook("around", Tag, 'yep', function(Tag_yep, self, message, _colour, func, ...)
  if RerollSurplus.in_reroll_sim then
    RerollSurplus.defer(func)
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

-- ANIMATION FUNCTIONS

RerollSurplus.Hook("around", _G, 'card_eval_status_text', function(card_eval_status_text, ...)
  if not RerollSurplus.skip_anims then return card_eval_status_text(...) end
end)

RerollSurplus.Hook("around", _G, 'juice_card', function(juice_card, ...)
  if not RerollSurplus.skip_anims then return juice_card(...) end
end)

RerollSurplus.Hook("around", Card, 'juice_up', function(Card_juice_up, ...)
  if not RerollSurplus.skip_anims then return Card_juice_up(...) end
end)

RerollSurplus.Hook("around", _G, 'play_sound', function(play_sound, ...)
  if not RerollSurplus.skip_anims then return play_sound(...) end
end)

RerollSurplus.Hook("around", Card, 'start_materialize', function(Card_start_materialize, ...)
  if not RerollSurplus.skip_anims then return Card_start_materialize(...) end
end)

-- EVENT QUEUE FUNCTIONS 

RerollSurplus.Hook("around", EventManager, "add_event", function(EventManager_add_event, self, event, queue, ...)
  if RerollSurplus.in_reroll_sim then
    queue = 'surplus_reroll_sim'
  end
  return EventManager_add_event(self, event, queue, ...)
end)