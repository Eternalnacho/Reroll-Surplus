-- UI DEFINITIONS FOR AUTO-REROLLER
local R = RerollSurplus.UI

function RerollSurplus.UIDEF.added_key_UI()
  local target_textnode = R.Text { ref_table = RerollSurplus.UI.targets, ref_value = 'added_target', scale = 0.3 }
  local nodes = R.Row { padding = 0.15, r = 0.2, minh = 0.8, minw = 4, colour = R.C.inactive, emboss = 0.05,
    nodes = {
      R.Text { text = "Search target added: ", colour = G.C.WHITE, shadow = true, scale = 0.3 },
      target_textnode
    }
  }
  local added_key_UI = R.Col { minw = 4.5, nodes = {nodes} }
  return added_key_UI
end

function RerollSurplus.FUNCS.get_type_collection_UIBox_func(set)
  local func
  if SMODS.ConsumableTypes[set] then
    func = SMODS.ConsumableTypes[set].create_UIBox_your_collection
  elseif set == 'Joker' then
    func = create_UIBox_your_collection_jokers
  end
  return func
end

function RerollSurplus.UI.rerender_collection(set)
  RerollSurplus.defer(function()
    RerollSurplus.UI.get_page_num, RerollSurplus.UI.rerendering = false, true
    RerollSurplus.UI.rerender(RerollSurplus.FUNCS.get_type_collection_UIBox_func(set), true, set)
    RerollSurplus.UI.get_page_num, RerollSurplus.UI.rerendering = true, false
  end)
end

function RerollSurplus.UI.reroll_options()
  return create_UIBox_generic_options({
    colour = G.C.BLACK,
    back_func = 'surplus_exit_reroll_config',
    contents = SMODS.Mods["RerollSurplus"].config_tab().nodes
  })
end