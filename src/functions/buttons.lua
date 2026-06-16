-- BUTTON FUNCTIONS

function G.FUNCS.surplus_your_collection(e)
  RerollSurplus.collection_from_button = true
  G.FUNCS.your_collection()
end

function G.FUNCS.surplus_exit_coll_config(e)
  SMODS.save_mod_config(RerollSurplus)
  G.FUNCS.your_collection()
end

function G.FUNCS.surplus_exit_search_collection()
  if G.SETTINGS.paused then
    RerollSurplus.collection_from_button = nil
    G.FUNCS.exit_overlay_menu()
  end
end

function G.FUNCS.surplus_clear_targets(e)
  if next(RerollSurplus.collection_targets) then
    RerollSurplus.FUNCS.clear_targets(true)
  end
end

function G.FUNCS.surplus_view_options(e)
  G.SETTINGS.paused = true
  RerollSurplus.config_from_collection = true
  RerollSurplus.in_collection = false
  G.FUNCS.overlay_menu{ definition = RerollSurplus.UI.config_from_collection() }
  G.OVERLAY_MENU:recalculate()
end