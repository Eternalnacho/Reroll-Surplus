local R = RerollSurplus.UI
local util = RerollSurplus.utils

RerollSurplus.UIDEF.get_target_window = function()
  return create_UIBox_generic_options({
    colour = G.C.BLACK,
    outline_colour = R.C.outline_colour,
    back_func = "exit_overlay_menu",
    contents = {
      R.Row({}, {
        R.Col(
          { padding = 0.15, minw = 8 },
          { RerollSurplus.UIDEF.card_searcher() }
        ),
        -- Spacer Column
        R.Col({ padding = 0.2 }),
        R.Col(
          { padding = 0.15, minw = 5 },
          { RerollSurplus.UIDEF.auto_reroll_menu_UI() }
        )
      })
    }
  })
end

RerollSurplus.UIDEF.card_searcher = function()
  local Searcher = RerollSurplus.Searcher({
    list = RerollSurplus.Centers,
    width = 5.5,
    search_funcs = RerollSurplus.FUNCS.card_search_funcs.search_funcs,
    exclude_funcs = RerollSurplus.FUNCS.card_search_funcs.exclude_funcs
  })
  Searcher.render_list = RerollSurplus.FUNCS.card_search_render
  Searcher.update_list = function(self, page)
    local list = self:get_list()
    RerollSurplus.UI.updateObject(self.id, self.render_list())
    RerollSurplus.UI.updateObject('RerollSurplusSearchOpts', RerollSurplus.FUNCS.card_search_pageOpts(list, page or 1))
    RerollSurplus.FUNCS.make_cards(list, page or 1)
  end
  RerollSurplus.defer(function() Searcher:update_list() end)

  local text_input = UIBox({
    definition = {
      n = G.UIT.ROOT,
      config = { colour = G.C.CLEAR },
      nodes = {
        Searcher:get_text_input()
      },
    },
    config = {
      align = "cm",
    },
  })

  return R.Col({ padding = 0.1, colour = R.C.inactive, emboss = 0.05, r = 0.2 }, {
    -- Search Field
    R.Row({}, {
      { n = G.UIT.O, config = { object = text_input } }
    }),
    -- Spacer Row
    R.Row {},
    -- Search Result List
    R.Row(
      { minh = 7, minw = 8 },
      { { n = G.UIT.O, config = { id = 'RerollSurplusSearchResult', object = Moveable() } }
    }),
    -- Spacer Row
    R.Row {},
    -- Page Selector
    R.Row(
      {},
      { { n = G.UIT.O, config = { id = 'RerollSurplusSearchOpts', object = Moveable() } }
    }),
  })
end

RerollSurplus.UIDEF.auto_reroll_menu_UI = function()
  local display_menu = UIBox({
    definition = RerollSurplus.UIDEF.reroll_targets_list("Current Targets:"),
    config = { type = "cm" }
  })
  return R.Col({},
    {
      R.Row(
        { padding = 0.1, r = 0.2 },
        {
          R.Col(
            { padding = 0.15, r = 0.2, minw = 5, colour = R.C.inactive, emboss = 0.05 },
            {
              R.Row(
                { padding = 0.1, r = 0.2 },
                { { n = G.UIT.O, config = { id = 'surplus_targetsList', object = display_menu } } }
              ),
              UIBox_button(
                {
                  button = 'surplus_clear_targets',
                  label = { "Clear Targets" },
                  colour = G.C.FILTER,
                  minw = 3,
                  minh = 0.7,
                  id = 'surplus_clear_targets_button'
                }
              ),
              R.Row(
                { padding = 0.1, r = 0.2 },
                { R.Text { text = "Select cards to reroll for\n\tby clicking on them", scale = 0.3 } }
              ),
            }
          ),
        }
      ),
      R.Row(
        { padding = 0.15, r = 0.2 },
        {
          R.Col(
            { padding = 0.15, r = 0.2, minw = 5, colour = darken(copy_table(G.C.GREY), 0.5), emboss = 0.05 },
            {
              UIBox_button(
                {
                  button = 'surplus_view_options',
                  label = { "Reroll Options" },
                  colour = G.C.FILTER,
                  minw = 3,
                  minh = 0.7,
                  id = 'surplus_view_options_button'
                }
              ),
            }
          ),
        }
      ),
      R.Row(
        { padding = 0.15, r = 0.2 },
        {
          R.Col(
            { padding = 0.15, r = 0.2, minw = 5, colour = darken(copy_table(G.C.GREY), 0.5), emboss = 0.05 },
            {
              UIBox_button(
                {
                  button = 'surplus_start_reroll',
                  label = { "Start Reroll" },
                  colour = G.C.FILTER,
                  minw = 3,
                  minh = 0.7,
                  id = 'surplus_start_reroll_button'
                }
              ),
            }
          ),
        }
      ),
    }
  )
end

--#region Targets List

local get_list_display = function()
  local display_list = R.Col(
    { colour = G.C.GREY },
    {
      R.Row({}, {
        R.Col(
          { colour = G.C.GREY, padding = 0.1, r = 0.2 },
          { --[[ Targets List ]] }
        )
      })
    }
  )
  local targets_list = display_list.nodes[1].nodes[1].nodes

  for i = 1, #RerollSurplus.collection_targets do
    -- Get localization entry if exists, if not use name or original key
    local key = RerollSurplus.collection_targets[i]
    
    local loc_target = G.localization.descriptions[G.P_CENTERS[key].set][key]
                   and G.localization.descriptions[G.P_CENTERS[key].set][key].name
    local target = loc_target or G.P_CENTERS[key].name or G.P_CENTERS[key].original_key

    -- Clean up any formatting in the target string
    target = util.clean_loc_str(target)
    target = string.gsub(target, '(%l)(%u)', '%1 %2')

    -- Insert Node
    table.insert(targets_list, R.Row(
      { r = 0.2, minw = 3 },
      { R.Text { text = target, colour = G.C.WHITE, scale = 0.4 } }
    ))
  end

  -- Use a default line if the list of targets is empty.
  local default_line = R.Row(
    { padding = 0.05, r = 0.2, minw = 3 },
    { R.Text({ padding = 0.05, text = '', colour = G.C.WHITE, scale = 0.4 }) }
  )
  if not next(targets_list) then table.insert(targets_list, default_line) end

  return display_list
end

RerollSurplus.UIDEF.reroll_targets_list = function(header)
  local display_list = get_list_display()
  table.insert(display_list.nodes, 1,
    R.Row { minh = 0.7, nodes = { R.Text { text = header, colour = G.C.UI.TEXT_LIGHT, scale = 0.5 } } })
  return R.UIBox (
    { minh = 0.0, minw = 0.0, bg_colour = R.C.inactive },
    { R.Row ({ r = 0.2, padding = 0.15 }, display_list.nodes) }
  )
end

--#endregion Targets List

--#region Card Searching

RerollSurplus.FUNCS.card_search_render = function()
  RerollSurplus.result_grid = RerollSurplus.result_grid or {}
  if next(RerollSurplus.result_grid) then
    for _, area in ipairs(RerollSurplus.result_grid) do area:remove() end
  end

  local render = R.UIBox (
    { minw = 7, minh = 6, bg_colour = G.C.GREY },
    { R.Col({}, RerollSurplus.FUNCS.make_card_areas()) }
  )
  return render
end

function RerollSurplus.FUNCS.make_card_areas()
  RerollSurplus.result_grid = {}
  local rows = 4
  local card_limit = 5
  local card_scale = 0.6
  local areas = {}
  for i = 1, rows do
    local area = CardArea(                                                                    --insert this cardarea into the table we feed to our ui
      0, 0,                                                                                   --position
      card_limit * G.CARD_W * 0.6,                                                            --width of cardarea
      0.95 * G.CARD_H * 0.6,                                                                  --height of cardarea
      { card_limit = card_limit, type = 'title_2', highlight_limit = 0, collection = true }   --basic config for a cardarea
    )
    RerollSurplus.result_grid[i] = area
    table.insert(areas, {
      n = G.UIT.R,
      config = { align = "cm", padding = 0.07 * card_scale, no_fill = true, scale = 1 * card_scale },
      nodes = { { n = G.UIT.O, config = { object = area } } }
    })
  end
  return areas
end

function RerollSurplus.FUNCS.make_cards(list, page)
  local rows, cols = #RerollSurplus.result_grid, 5
  local startIndex = ( page - 1 ) * ( rows * cols )

  for row = 1, rows do
    for col = 1, cols do
      local target = startIndex + 5 * (row - 1) + col
      local center = list[target]

      if center and center.key then
        local used_jokers = copy_table(G.GAME.used_jokers)
        
        local card = RerollSurplus.utils.safe_card_from_center(center.key, RerollSurplus.result_grid[row],
          {
            silent = true,
            scale = { w = 0.6, h = 0.6 },
          }
        )
        if card then RerollSurplus.result_grid[row]:emplace(card) end
        
        G.GAME.used_jokers = used_jokers
      end
    end
  end
end

local recalculateList = function(list, page)
  page = page or 1
  local rows, cols = 4, 5
  local totalPages = math.ceil( #list / ( rows * cols ) )
  local currentPage = localize('k_page') .. ' ' .. page .. "/" .. totalPages

  local pageOptions = {}
  for i = 1, totalPages do
    table.insert(pageOptions, (localize('k_page') .. ' ' .. tostring(i) .. "/" .. totalPages))
  end

  return currentPage, pageOptions
end

RerollSurplus.FUNCS.card_search_pageOpts = function(list, page)
  local currentPage, pageOptions = recalculateList(list, page)
  return R.UIBox (
    { minw = 7, minh = 1 },
    {
      R.Col(
        {},
        {
          SMODS.GUI.createOptionSelector({
            colour = R.C.active,
            scale = 0.8,
            options = pageOptions,
            opt_callback = 'RerollSurplus_update_search',
            no_pips = true,
            id = 'RerollSurplusSearchOptSelect',
            current_option = ( currentPage )
          })
        }
      )
    }
  )
end

--#endregion Card Searching