-- BUTTON FUNCTIONS

function G.FUNCS.surplus_open_targeting_window(e)
  if not RerollSurplus.Centers then RerollSurplus.FUNCS.process_centers() end
  G.SETTINGS.paused = true
  RerollSurplus.targeting = true
  G.FUNCS.overlay_menu{ definition = RerollSurplus.UIDEF.get_target_window() }
  G.OVERLAY_MENU:recalculate()
end

function G.FUNCS.surplus_exit_reroll_config(e)
  SMODS.save_mod_config(SMODS.Mods["RerollSurplus"])
  G.FUNCS.surplus_open_targeting_window()
end

function G.FUNCS.surplus_exit_targeting_window(e)
  if G.SETTINGS.paused then
    RerollSurplus.targeting = false
    G.FUNCS.exit_overlay_menu()
  end
end

function G.FUNCS.surplus_clear_targets(e)
  if next(RerollSurplus.collection_targets) then
    RerollSurplus.FUNCS.clear_targets(true)
  end
end

function G.FUNCS.surplus_open_reroll_config(e)
  G.SETTINGS.paused = true
  G.FUNCS.overlay_menu{ definition = RerollSurplus.UI.reroll_options() }
  G.OVERLAY_MENU:recalculate()
end

function G.FUNCS.surplus_start_reroll(e)
  RerollSurplus.REROLL.a_limit = RerollSurplus.config.reroll_limit
  RerollSurplus.REROLL.m_savings = RerollSurplus.config.reroll_safety_threshold
  if next(RerollSurplus.collection_targets) then
    G.FUNCS.surplus_exit_targeting_window()
    RerollSurplus.defer(function()
      RerollSurplus.FUNCS.start_auto_reroll(RerollSurplus.collection_targets)
    end, { delay = 0.4, blockable = true })
  end
end