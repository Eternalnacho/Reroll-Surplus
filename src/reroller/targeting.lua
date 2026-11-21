local R = RerollSurplus.UI
local util = RerollSurplus.utils

-- thank you Overstock and god bless you
local function can_reroll_into(card_key)
  if not RerollSurplus.config.enable_auto_reroll or G.STATE ~= G.STATES.SHOP then return end
  if G.GAME.banned_keys and G.GAME.banned_keys[card_key] then return false end

  local center = G.P_CENTERS[card_key]
  if not center then return false end
  if center.no_appear_in_shop then return false end

  if center.yes_pool_flag and (not G.GAME.pool_flags or not G.GAME.pool_flags[center.yes_pool_flag]) then return false end
  if center.no_pool_flag and (G.GAME.pool_flags and G.GAME.pool_flags[center.no_pool_flag]) then return false end

  if center.set == 'Edition' and not center.in_shop then return false end

  if ({
        Enhanced = true,
        Back = true,
        Booster = true,
        Spectral = G.GAME.spectral_rate <= 0,
        Voucher = true
      })[center.set] then
    return false
  end
  return true
end

local function is_reroll_button(target)
  return G.STATE == G.STATES.SHOP
     and target.config.button == "reroll_shop"
     and target.config.func == "can_reroll"
end

function RerollSurplus.FUNCS.prompt_target(target)
  if not RerollSurplus.Centers then RerollSurplus.FUNCS.process_centers() end

  if type(RerollSurplus.config.reroll_limit) ~= 'number' then
    RerollSurplus.config.reroll_limit = tonumber(RerollSurplus.config.reroll_limit) or 30
  end

  if is_reroll_button(target) and RerollSurplus.config.enable_auto_reroll then
    if next(RerollSurplus.collection_targets) and SurplusInputManager.is_shift_held() then
      RerollSurplus.FUNCS.auto_reroll(RerollSurplus.collection_targets)
    else
      G.FUNCS.surplus_open_targeting_window()
    end
  end
end

function RerollSurplus.FUNCS.clear_targets(from_button)
  if next(RerollSurplus.collection_targets) and (SurplusInputManager.is_shift_held() or from_button == true) then
    RerollSurplus.collection_targets = {}
    if RerollSurplus.targeting then
      local def = RerollSurplus.UIDEF.reroll_targets_list("Current Targets:")
      RerollSurplus.UI.updateObject('surplus_targetsList', def)
    elseif G.STATE == G.STATES.SHOP and not G.SETTINGS.paused then
      attention_text({
        text = localize("b_Surplus_targets_cleared"),
        scale = 0.7,
        hold = 2 * G.SPEEDFACTOR,
        align = 'cm',
        offset = { x = 0, y = -2.5 }, major = G.ROOM_ATTACH,
      })
    end
  end
end

-- Hook card clicks to add search targets
RerollSurplus.Hook("before", Card, "click", function(self)
  local is_targetable = self.area and self.area.config.collection and can_reroll_into(self.config.center_key)
                              and not util.contains(RerollSurplus.collection_targets, self.config.center_key)
  if is_targetable then
    table.insert(RerollSurplus.collection_targets, self.config.center_key)

    if RerollSurplus.targeting then
      local def = RerollSurplus.UIDEF.reroll_targets_list("Current Targets:")
      RerollSurplus.UI.updateObject('surplus_targetsList', def)
    end
  end
end)

-- Reroller controls
SurplusInputManager:add_listener({ 'right_click', 'right_stick' }, RerollSurplus.FUNCS.prompt_target)
SurplusInputManager:add_listener({ 'double_click' }, RerollSurplus.FUNCS.clear_targets)


-- Search Funcs (I'm *very blatantly* ripping from TMJ here)
RerollSurplus.FUNCS.card_search_funcs = {
  search_funcs = {
    -- If searching for an exact set (i.e. "Planet"), show centers of the set first
    set_matches_str = function(center, query)
      local Search = RerollSurplus.ACTIVE_SEARCH
      return center.set and Search.query:lower() == center.set:lower()
    end,
    name_contains_str = function(center, query)
      local Search = RerollSurplus.ACTIVE_SEARCH
      return center.name and util.has_str(center.name, Search.query)
    end,
    mod_contains_str = function(center, query)
      local Search = RerollSurplus.ACTIVE_SEARCH
      return center.original_mod and center.original_mod.name and util.has_str(center.original_mod.name, Search.query)
          or util.has_str("vanilla", Search.query)
    end,
    desc_contains_str = function(center)
      local Search = RerollSurplus.ACTIVE_SEARCH
      local description = G.localization.descriptions[center.set][center.key]
      if description then
        local name = description.name
        local name_cleaned = type(name) == "table" and util.tableToString(name, '') or name

        local text = description.text
        if type(text) == "table" then
          text = util.map_list(text, util.clean_loc_str)
          text = table.concat(text, '')
        elseif type(text) == "string" then
          text = util.clean_loc_str(text)
        end

        return name_cleaned and util.has_str(name_cleaned, Search.query)
            or text and util.has_str(text, Search.query)
      end
    end,
  },

  exclude_funcs = {
    not_no_collection = function(center) return not center.no_collection end,
    is_valid_target = function(center) return can_reroll_into(center.key) end,
  }
}

RerollSurplus.blacklisted_pools = util.tableToHashset { "Joker", "Tag" }
RerollSurplus.blacklisted_sets = util.tableToHashset { "Stake", "Seal", "Back", "Sleeve", "Booster", "Default" }
function RerollSurplus.FUNCS.process_centers()
  RerollSurplus.Centers = {}
  local seen = {}
  --insert jokers first to be at the top of the list
  for _, center in pairs(G.P_CENTER_POOLS.Joker) do
    if not seen[center.key] then
      seen[center.key] = true
      table.insert(RerollSurplus.Centers, center)
    end
  end
  for poolName, pool in pairs(G.P_CENTER_POOLS) do
    if not RerollSurplus.blacklisted_pools[poolName] then
      for _, center in pairs(pool) do
        if not center.set or not RerollSurplus.blacklisted_sets[center.set] then
          if not seen[center.key] then
            seen[center.key] = true
            table.insert(RerollSurplus.Centers, center)
          end
        end
      end
    end
  end
end