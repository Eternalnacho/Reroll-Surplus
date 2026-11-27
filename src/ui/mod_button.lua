local R = RerollSurplus.UI

local prompt_button_nodes = function()
  local mod_sprite = Sprite(0, 0, 1, 1, SMODS.get_atlas('Surplus_modicon'))
  return R.Col(
    {
      reroll_surplus_prompt_button = true,
      padding = 0.0,
      minw = 0.8, minh = 0.8, maxw = 0.8, maxh = 0.8,
      button = 'surplus_open_targeting_window',
      hover = true,
      shadow = true,
    },
    {
      {
        n = G.UIT.O,
        config = {
          object = mod_sprite,
          align = 'cm',
          w = 0.8,
          h = 0.8,
        },
      }
    }
  )
end

local function reshape_shop_buttons(node)
  if type(node) ~= 'table' or type(node.nodes) ~= 'table' then
    return false
  end

  local reroll_node, reroll_index
  for index, child in ipairs(node.nodes) do
    local config = child.config
    if config and config.button == 'reroll_shop' then
      reroll_node, reroll_index = child, index
      break
    end
  end

  if reroll_index and reroll_node then
    reroll_node.config.minw = 1.8
    reroll_node.config.maxw = 1.8
    local split_row = R.Row({},
      {
        R.Col({ minw = 1.4, padding = 0.0 }, { reroll_node }),
        R.Col({}),
        R.Col({ minw = 0.8, padding = 0.0 }, { prompt_button_nodes() }),
      })
    node.nodes[reroll_index] = split_row
    return true
  end

  for _, child in ipairs(node.nodes) do
    if reshape_shop_buttons(child) then
      return true
    end
  end
  return false
end

RerollSurplus.Hook("around", G.UIDEF, "shop", function(G_UIDEF_SHOP, ...)
  local shop = G_UIDEF_SHOP()
  reshape_shop_buttons(shop)
  return shop
end)

RerollSurplus.Hook('before', UIElement, 'hover', function(self)
  if self.config and self.config.reroll_surplus_prompt_button then
    local mod_sprite = self.children[1] and self.children[1].config.object
    mod_sprite:define_draw_steps({
      { shader = 'dissolve', shadow_height = 0.05 },
      { shader = 'dissolve' },
      { shader = 'dissolve', shadow_height = 0, tilt_shadow = 0.5 }
    })
  end
end)

RerollSurplus.Hook('before', UIElement, 'stop_hover', function(self)
  if self.config and self.config.reroll_surplus_prompt_button then
    local mod_sprite = self.children[1] and self.children[1].config.object
    mod_sprite:define_draw_steps({
      { shader = 'dissolve', shadow_height = 0.05 },
      { shader = 'dissolve' },
    })
  end
end)