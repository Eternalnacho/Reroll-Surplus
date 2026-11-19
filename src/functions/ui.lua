-- UI FUNCTIONS
RerollSurplus.UI.mod_colours = {
  buttons = mix_colours(G.C.GREEN, G.C.GREY, 0.8),
  active = mix_colours(G.C.FILTER, G.C.RED, 0.5),
  inactive = darken(copy_table(G.C.GREY), 0.5),
  colour = mix_colours(G.C.UI.BACKGROUND_INACTIVE, {0, 0.1, 0.2, 1}, 0.8),
}
RerollSurplus.UI.mod_colours.bg_colour = mix_colours({0.5, 0.5, 0.5, 1}, RerollSurplus.UI.mod_colours.colour, 0.5)
RerollSurplus.UI.mod_colours.outline_colour = mix_colours(RerollSurplus.UI.mod_colours.colour, G.C.WHITE, 0.7)

-- UIElement args
function RerollSurplus.UI.UIE_config_args(args)
  local default_values = {
    ['align'] = "cm",
    ['padding'] = 0.05,
    ['colour'] = G.C.CLEAR,
  }
  local new_args = SMODS.merge_defaults(args, default_values)
  return new_args
end

-- Column node wrapper
function RerollSurplus.UI.create_column(args, nodes)
  return {
    n = G.UIT.C,
    config = RerollSurplus.UI.UIE_config_args(args),
    nodes = nodes or args.nodes or {}
  }
end

-- Row node wrapper
function RerollSurplus.UI.create_row(args, nodes)
  return {
    n = G.UIT.R,
    config = RerollSurplus.UI.UIE_config_args(args),
    nodes = nodes or args.nodes or {}
  }
end

-- Root node wrapper
function RerollSurplus.UI.create_root_node(args, nodes)
  return {
    n = G.UIT.ROOT,
    config = RerollSurplus.UI.UIE_config_args(args),
    nodes = nodes or args.nodes or {}
  }
end

-- Text node wrapper
function RerollSurplus.UI.create_text_node(args)
  return {
    n = G.UIT.T,
    config = {
      text = args.text,
      ref_table = args.ref_table,
      ref_value = args.ref_value,
      scale = args.scale or 1,
      colour = args.colour or G.C.WHITE,
      shadow = args.shadow,
      vert = args.vert
    }
  }
end

-- Number input node wrapper
function RerollSurplus.UI.create_number_node(args)
  return RerollSurplus.UI.create_num_input({
    id = args.id,
    colour = args.colour,
    hooked_colour = args.hooked_colour,
    w = 2, h = 1,
    prompt_text = "",
    ref_table = args.ref_table or RerollSurplus.config,
    ref_value = args.ref_value,
    extended_corpus = true,
    keyboard_offset = 1,
    callback = args.callback
  })
end


-- I am VERY BLATANTLY ripping these straight from Cartomancer

---@param config table
---@param contents table?
function RerollSurplus.UI.create_UIBox_generic_options_custom(config, contents)
  config = config or {}
  local translucent_grey = copy_table(G.C.GREY); translucent_grey[4] = 0.7
  return {
    n = G.UIT.ROOT,
    config = {
      align = config.align or "cm",
      minw = config.minw or G.ROOM.T.w * 0.6,
      emboss = config.emboss,
      padding = config.padding or 0.0,
      outline = config.outline,
      outline_colour = config.outline and config.outline_colour,
      r = 0.1,
      colour = config.bg_colour or translucent_grey
    },
    nodes = { RerollSurplus.UI.create_column({ padding = 0.0, minh = config.minh or 3, nodes = contents or config.contents }) }
  }
end

-- UIBox refresh function
---@param id string
function RerollSurplus.UI.updateObject(id, definition, offset)
  local object = G.OVERLAY_MENU:get_UIE_by_ID(id)
  if object and definition then
    object.config.object:remove()
    object.config.object = UIBox({
      definition = definition,
      config = {type = "cm", parent = object, offset = offset}
    })
    object.UIBox:recalculate()
  end
end

-- Stole this from Handy
function RerollSurplus.UI.rerender(def, silent, set)
  local result = set and { definition = def(SMODS.ConsumableTypes[set]) } or { definition = def() }
  if silent then
    G.ROOM.jiggle = G.ROOM.jiggle - 1
    result.config = {
      offset = {
        x = 0,
        y = 0,
      },
    }
  end
  G.FUNCS.overlay_menu(result)
  G.OVERLAY_MENU:recalculate()
  RerollSurplus.UI.cleanup_dead_elements(G, "MOVEABLES")
end

function RerollSurplus.UI.cleanup_dead_elements(ref_table, ref_key)
	local new_values = {}
	local target = ref_table[ref_key]
	if not target then
		return
	end
	for _, v in pairs(target) do
		if not v.REMOVED and not v.removed then
			new_values[#new_values + 1] = v
		end
	end
	ref_table[ref_key] = new_values
	return new_values
end

-- Create shorthands for UI Helper Functions
SMODS.merge_defaults(RerollSurplus.UI, {
  ['Row'] = RerollSurplus.UI.create_row,
  ['Col'] = RerollSurplus.UI.create_column,
  ['Text'] = RerollSurplus.UI.create_text_node,
  ['Num'] = RerollSurplus.UI.create_number_node,
  ['Root'] = RerollSurplus.UI.create_root_node,
  ['UIBox'] = RerollSurplus.UI.create_UIBox_generic_options_custom,
  ['C'] = RerollSurplus.UI.mod_colours,
})