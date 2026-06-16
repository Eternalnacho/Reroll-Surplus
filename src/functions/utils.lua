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
  }))
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

function containsString(str, substring)
	local lowerStr = string.lower(str)
	local lowerSubstring = string.lower(substring)
	return string.find(lowerStr, lowerSubstring, 1, true) ~= nil
end

-- card functions
function RerollSurplus.utils.safe_card_from_center(center_key, area)
	local card = SMODS.create_card({
		key = "c_base",
		front = false,
		area = area,
		bypass_discovery_center = true,
		bypass_discovery_ui = true,
		bypass_lock = true,
	})
	local success = pcall(function()
		card:set_ability(center_key, false, false)
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

function RerollSurplus.hook_before_function(table, funcname, hook)
  if not table[funcname] then
    table[funcname] = hook
  else
    local orig = table[funcname]
    table[funcname] = function(...)
      return hook(...)
          or orig(...)
    end
  end
end

function RerollSurplus.hook_after_function(table, funcname, hook, always_run)
  if not table[funcname] then
    table[funcname] = hook
  else
    local orig = table[funcname]
    if always_run then
      table[funcname] = function(...)
        local ret = orig(...)
        local hook_ret = hook(...)
        return ret or hook_ret
      end
    else
      table[funcname] = function(...)
        return orig(...)
            or hook(...)
      end
    end
  end
end