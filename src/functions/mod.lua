---@diagnostic disable: duplicate-set-field

local Reroller = RerollSurplus.REROLL

SMODS.current_mod.calculate = function(self, context)
  if context.prevent_tag_trigger then
    Reroller.tag_queue[#Reroller.tag_queue + 1] = context.prevent_tag_trigger
  end
end