---@diagnostic disable: duplicate-set-field
-- CONFIG TAB UI
local R = RerollSurplus.UI

SMODS.current_mod.ui_config = {
  colour = R.C.colour,
  outline_colour = R.C.outline_colour,
  tab_button_colour = darken(R.C.buttons, 0.2),
  back_colour = R.C.active,
  -- misc. colours
  author_colour = HEX('E9B800'),
}

function SMODS.current_mod.config_tab()
  local reroll_cost = G.STATES == G.STATES.RUN and G.GAME.current_round and G.GAME.current_round.reroll_cost or 5
  RerollSurplus.REROLL.reroll_limit_price = '$'..(math.summ(RerollSurplus.config.reroll_limit + reroll_cost - 1) - math.summ(reroll_cost - 1))
  return R.UIBox({
    padding = 0.15, minw = 7, emboss = 0.05, bg_colour = G.C.BLACK,
    contents = {
      R.Col { padding = 0.2, nodes = {
        R.Row { r = 0.1, outline = 1, outline_colour = R.C.outline_colour, nodes = {
          R.Text { align = "tm", text = "Reroll Settings", scale = 0.7 }
        }},
        R.Row { nodes = {
          R.Col { r = 0.2, colour = R.C.colour, emboss = 0.05, nodes = {
            R.Row { nodes = {
              R.Col { align = 'cr', nodes = {
                R.Row { align = 'cr', nodes = {
                  create_toggle({
                    align = 'cr',
                    w = 0, h = 0,
                    active_colour = R.C.buttons,
                    label = 'Enable Auto Reroll?',
                    callback = RerollSurplus.UI.update_config,
                    ref_table = RerollSurplus.config,
                    ref_value = 'enable_auto_reroll'
                  })
                }},
                R.Row { align = 'cr', nodes = {
                  create_toggle({
                    align = 'cr',
                    w = 0,
                    label = 'Skip Reroll Animations?',
                    active_colour = RerollSurplus.config.enable_auto_reroll and R.C.buttons or R.C.inactive,
                    ref_table = RerollSurplus.config,
                    ref_value = 'skip_reroll_anims'
                  })
                }},
              }}
            }},
            R.Row { padding = 0.1, nodes = {
              R.Col ({ r = 0.15, padding = 0.1, colour = G.C.GREY, emboss = 0.05 }, {
                R.Row ({ align = 'cr'}, {
                  R.Text { text = "Reroll Limit:  ", scale = 0.4 },
                  R.Num {
                    id = "surplus_set_reroll_limit",
                    colour = RerollSurplus.config.enable_auto_reroll and R.C.active or R.C.inactive,
                    hooked_colour = RerollSurplus.config.enable_auto_reroll and darken(R.C.active, 0.3) or R.C.inactive,
                    ref_value = "reroll_limit", default = 30,
                    prompt_text = '' .. RerollSurplus.REROLL.reroll_limit_price,
                    callback = function()
                      local r_cost = G.STATES == G.STATES.RUN and G.GAME.current_round and G.GAME.current_round.reroll_cost or 5
                      RerollSurplus.REROLL.reroll_limit_price = '$'..(math.summ(RerollSurplus.config.reroll_limit + r_cost - 1) - math.summ(r_cost - 1))
                    end
                  },
                }),
                -- R.Row ({ align = 'cr', padding = 0 }, {
                --   R.Col ({ padding = 0 }, { R.Text { ref_table = RerollSurplus.REROLL, ref_value = 'reroll_limit_price', scale = 0.4 } })
                -- }),
                R.Row ({ align = 'cr' }, {
                  R.Text { text = "Savings Threshold: $", scale = 0.4 },
                  R.Num {
                    id = "surplus_set_spend_limit",
                    colour = RerollSurplus.config.enable_auto_reroll and R.C.active or R.C.inactive,
                    hooked_colour = RerollSurplus.config.enable_auto_reroll and darken(R.C.active, 0.3) or R.C.inactive,
                    ref_value = "reroll_safety_threshold", default = 25,
                  }
                })
              })
            }}
          }}
        }}
      }}
    }
  })
end

function RerollSurplus.UI.update_config()
  if RerollSurplus.targeting then
    RerollSurplus.UI.rerender(RerollSurplus.UI.reroll_options, true)
  else
    G.ACTIVE_MOD_UI = SMODS.Mods["RerollSurplus"]
    RerollSurplus.UI.rerender(create_UIBox_mods, true)
  end
end