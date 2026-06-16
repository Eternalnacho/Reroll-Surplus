local card_collection_uibox = SMODS.card_collection_UIBox
SMODS.card_collection_UIBox = function(_pool, rows, args)
  args.no_materialize = RerollSurplus.adding_key and true or args.no_materialize
  if RerollSurplus.UI.rerendering then args.surplus_curr_option = RerollSurplus.UI.curr_page end
  return card_collection_uibox(_pool, rows, args)
end

local old_FUNCS_your_collection = G.FUNCS.your_collection
function G.FUNCS.your_collection(...)
  RerollSurplus.in_collection = true
  RerollSurplus.config_from_collection = nil
  RerollSurplus.UI.targets.added_target = ''
  return old_FUNCS_your_collection(...)
end

local uibox_your_collection = create_UIBox_your_collection
create_UIBox_your_collection = function()
  local ret = uibox_your_collection()
  -- Changing the back button function if collection was called from the button
    -- also thank you to NeatoJokers for showing me this trick
  local back_button_deepfind = SMODS.deepfind(ret, 'overlay_menu_back_button', true)[1]
  if back_button_deepfind then
    local back_button = back_button_deepfind.objtree[#back_button_deepfind.objtree - 2]
    back_button.config.button = RerollSurplus.collection_from_button and 'surplus_exit_search_collection' or back_button.config.button
  end

  -- Adding the Auto-reroll UI
  table.insert(ret.nodes[1].nodes[1].nodes[1].nodes, (RerollSurplus.collection_from_button or next(RerollSurplus.collection_targets)) and RerollSurplus.UIDEF.auto_reroll_menu_UI())
  return ret
end

local old_FUNCS_exit_overlay_menu = G.FUNCS.exit_overlay_menu
function G.FUNCS.exit_overlay_menu(...)
  RerollSurplus.UI.reset_ui_states()
  return old_FUNCS_exit_overlay_menu(...)
end