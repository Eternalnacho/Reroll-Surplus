-- UTILITY FUNCTIONS
RerollSurplus.utils = {}

-- List functions
function RerollSurplus.utils.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function RerollSurplus.utils.filter(list, func)
  local new_list = {}
  for _, v in pairs(list) do
    if func(v) then
      new_list[#new_list + 1] = v
    end
  end
  return new_list
end

function RerollSurplus.utils.for_each(list, func)
  for _, v in pairs(list) do
    func(v)
  end
end

function RerollSurplus.utils.copy_list(list)
  return RerollSurplus.utils.map_list(list, RerollSurplus.utils.id)
end

function RerollSurplus.utils.map_list(list, func)
  local new_list = {}
  for _, v in pairs(list) do
    new_list[#new_list + 1] = func(v)
  end
  return new_list
end

function RerollSurplus.utils.id(a)
  return a
end

function RerollSurplus.utils.index_list(list)
  local new_list = {}
  for k, v in pairs(list) do
    if not new_list[v] then new_list[v] = k end
  end
  return new_list
end

function RerollSurplus.utils.tableToString(tbl, sep)
  local result = {}
  for _, line in ipairs(tbl) do
      local cleanedLine = line:gsub("{.-}", "")
      table.insert(result, cleanedLine)
  end
  return table.concat(result, (sep or " "))
end

function RerollSurplus.utils.tableToHashset(tbl)
    local new = {}
    for i, v in pairs(tbl) do
        new[v] = true
    end
    setmetatable(new, {
        __newindex = function (t, k, v)
            assert(type(v) == "boolean", "misuse of hashset")
            rawset(t, k, v or nil)
        end,
        __index = function (t, k)
            if k == "set" then
                return function(self, key)
                    rawset(self, key, true)
                end
            else
                return rawget(t, k)
            end
        end
    })
    return new
end

function RerollSurplus.defer(func, args) -- Stealing this one from Emma holy moly that's useful
  if not args then args = {} end
  G.E_MANAGER:add_event(Event({
    trigger = args.trigger or args.delay and 'after',
    delay = args.delay,
    func = function()
      func()
      return true
    end,
    blocking = args.blocking or true,
    blockable = args.blockable or false,
  }), args.queue)
end

-- math functions
to_number = to_number or function(x) return x end

function math.summ(n)
  return n * (n + 1) / 2
end

function math.round(n)
  return n * 10 % 10 < 5 and math.floor(n) or math.ceil(n)
end

function math.clamp(num, min, max)
  max = max or math.huge
  min = min or -math.huge
  assert(min <= max)
  return math.min(math.max(num, min), max)
end

-- string functions
function starts_with(str, start)
	return string.sub(str, 1, #start) == start
end

function ends_with(str, ending)
	return string.sub(str, -#ending) == ending
end

function RerollSurplus.utils.has_str(str, substring)
	local lowerStr = string.lower(str)
	local lowerSubstring = string.lower(substring)
	return string.find(lowerStr, lowerSubstring, 1, true) ~= nil
end

function RerollSurplus.utils.clean_loc_str(str)
  local newstr = str
  newstr = string.gsub(newstr, "{[^}]+}", "") --remove any formatting tags, e.g. {C:legendary}
  newstr = string.gsub(newstr, "#[^#]+#", "") --remove locvar tags, e.g. #1#
  newstr = string.gsub(newstr, "{}", "")      --remove ending formatting tags, e.g. {}
  return newstr
end

-- card functions
function RerollSurplus.utils.safe_card_from_center(center_key, area, card_args)
  local defaults = {
		key = "c_base",
		front = false,
		area = area,
		bypass_discovery_center = true,
		bypass_discovery_ui = true,
		bypass_lock = true,
	}
  local args = SMODS.merge_defaults(defaults, card_args)
	local card = SMODS.create_card(args)
	local success = pcall(function()
		card:set_ability(center_key, false, false)
    if G.P_CENTERS[center_key] and G.P_CENTERS[center_key].set == "Edition" then
      card:set_edition(center_key, true, true)
    end
	end)
	if success then
		return card
	else
		card:remove()
		return nil
	end
end

-- table functions
table.unpack = table.unpack or unpack

-- hooking functions helper

local hooks = {
  before = function (table, funcname, hook)
    local orig = table[funcname] or function(...) end
    table[funcname] = function(...) return hook(...) or orig(...) end
  end,

  after = function (table, funcname, hook, prevent_run)
    local orig = table[funcname] or function(...) end
    table[funcname] = function(...)
      local ret = orig(...)
      local h_ret = (not prevent_run or ret) and hook(...)
      return ret or h_ret
    end
  end,

  around = function (table, funcname, hook)
    local orig = table[funcname] or function(...) end
    table[funcname] = function(...) return hook(orig, ...) end
  end,
}

---@param hook_type
---| "before" # Pre-Call processing
---| "after"  # Post-Call processing
---| "around" # Pre-or-Post-Call processing (requires orig in hook)
---@param table any
---@param funcname string
---@param hook function
---@param prevent_run boolean?
RerollSurplus.Hook = function(hook_type, table, funcname, hook, prevent_run)
  if not hook then return end
  if hooks[hook_type] then hooks[hook_type](table, funcname, hook, hook_type == 'after' and prevent_run) end
end

RerollSurplus.utils.noop = function() end