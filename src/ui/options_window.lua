function RerollSurplus.UI.reroll_options()
  return create_UIBox_generic_options({
    colour = G.C.BLACK,
    back_func = 'surplus_exit_reroll_config',
    contents = SMODS.Mods["RerollSurplus"].config_tab().nodes
  })
end