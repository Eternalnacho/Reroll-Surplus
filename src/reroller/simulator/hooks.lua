-- REROLL SIMULATOR FUNCTION HOOKS


-- CARD CREATION FUNCTIONS

local s_create_card_ref = SMODS.create_card
SMODS.create_card = function(t)
  if RerollSurplus.in_reroll_sim and RerollSurplus.from_tag then
    RerollSurplus.REROLL.tag_args = copy_table(t)
    RerollSurplus.REROLL.from_scc = true
  end
  local ret = s_create_card_ref(t)
  RerollSurplus.REROLL.from_scc, RerollSurplus.from_tag = nil, nil
  return ret
end

local create_card_ref = create_card
create_card = function(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append, ...)
  if RerollSurplus.in_reroll_sim and not RerollSurplus.REROLL.from_scc then
    RerollSurplus.REROLL.tag_args = {
      set = _type,
      legendary = legendary,
      rarity = _rarity,
      key = forced_key,
      key_append = key_append
    }
  end
  local ret = create_card_ref(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append, ...)
  return ret
end


-- TAG FUNCTIONS

local yep = Tag.yep
function Tag:yep(...)
  if RerollSurplus.in_reroll_sim then
    self.triggered = false
    return
  else yep(self, ...) end
end

local nope = Tag.nope
function Tag:nope()
  if RerollSurplus.in_reroll_sim then
    self.triggered = false
    return
  else nope(self) end
end

local apply_to_run = Tag.apply_to_run
function Tag:apply_to_run(...)
  local ret = apply_to_run(self, ...)
  if RerollSurplus.in_reroll_sim then
    self.triggered = false
  end
  return ret
end


-- CALCULATION FUNCTIONS

local cest = card_eval_status_text
function card_eval_status_text(...)
  if not RerollSurplus.skip_anims then cest(...) end
end

local jc = juice_card
function juice_card(...)
  if not RerollSurplus.skip_anims then jc(...) end
end

local cju = Card.juice_up
function Card:juice_up(...)
  if not RerollSurplus.skip_anims then cju(self, ...) end
end