-- UI DEFINITIONS FOR AUTO-REROLLER
local R = RerollSurplus.UI

function RerollSurplus.UIDEF.auto_reroll_menu_UI()
  local display_menu = UIBox({ definition = RerollSurplus.UIDEF.reroll_targets_list("Current Targets:"), config = {type = "cm"}})
  return
    R.Col { padding = 0.15, minw = 5, nodes = {
      R.Row { padding = 0.1, r = 0.2, nodes = {
        R.Col { padding = 0.15, r = 0.2, minw = 5, colour = R.C.inactive, emboss = 0.05, nodes = {
          R.Row { padding = 0.1, r = 0.2, nodes = {{ n = G.UIT.O, config = { id = 'surplus_targetsList', object = display_menu } }} },
          UIBox_button({button = 'surplus_clear_targets', label = {"Clear Targets"}, colour = G.C.FILTER, minw = 3, minh = 0.7, id = 'surplus_clear_targets_button'}),
          R.Row { padding = 0.1, r = 0.2, nodes = { R.Text{text = "Select cards to reroll for\n\tby clicking on them", scale = 0.3} } },
        }},
      }},
      R.Row { padding = 0.15, r = 0.2, nodes = {
        R.Col { padding = 0.15, r = 0.2, minw = 5, colour = darken(copy_table(G.C.GREY), 0.5), emboss = 0.05, nodes = {
          UIBox_button({button = 'surplus_view_options', label = {"Reroll Options"}, colour = G.C.FILTER, minw = 3, minh = 0.7, id = 'surplus_view_options_button'}),
          R.Row { nodes = { R.Text{text = "\t Start auto-reroll with\nShift+Right-Click on reroll button", scale = 0.28} } },
        }},
      }},
    }}
end

function RerollSurplus.UIDEF.reroll_targets_list(header)
  local display_list = RerollSurplus.UIDEF.get_display_list()
  table.insert(display_list.nodes, 1, R.Row { minh = 0.7, nodes = { R.Text { text = header, colour = G.C.UI.TEXT_LIGHT, scale = 0.5 } } })
  return R.UIBox{ minh = 0.0, minw = 0.0, bg_colour = R.C.inactive, contents = { R.Row { r = 0.2, padding = 0.15, nodes = display_list.nodes } } }
end

function RerollSurplus.UIDEF.get_display_list()
  local display_list = R.Col { colour = G.C.GREY, nodes = { R.Row { nodes = { R.Col { colour = G.C.GREY, padding = 0.05, r = 0.2, nodes = {} } }} }}
  local default = R.Row { padding = 0.05, r = 0.2, minw = 3, nodes = { R.Text { padding = 0.05, text = '', colour = G.C.WHITE, scale = 0.4 } } }
  for i = 1, #RerollSurplus.collection_targets do
    local target = G.P_CENTERS[RerollSurplus.collection_targets[i]].name or G.P_CENTERS[RerollSurplus.collection_targets[i]].original_key
    target = string.gsub(target, '^%w', function(l) return l:upper() end)
    target = string.gsub(target, '_%w', function(l) return l:upper() end)
    table.insert(display_list.nodes[1].nodes[1].nodes, R.Row { padding = 0.05, r = 0.2, minw = 3,
      nodes = { R.Text { padding = 0.05, text = target, colour = G.C.WHITE, scale = 0.4 } } })
  end
  if not next(display_list.nodes[1].nodes[1].nodes) then table.insert(display_list.nodes[1].nodes[1].nodes, default) end
  return display_list
end

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

function RerollSurplus.UI.config_from_collection()
  return create_UIBox_generic_options({
    colour = G.C.BLACK,
    back_func = 'surplus_exit_coll_config',
    contents = SMODS.Mods["RerollSurplus"].config_tab().nodes})
end