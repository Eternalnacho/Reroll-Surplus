
RerollSurplus = {
  FUNCS = {},
  UIDEF = {},
  UI = {},

  config = SMODS.current_mod.config
}

-- Get directory loader
local load_dir = assert(SMODS.load_file("src/loader.lua"))()

-- Load directories
for _, path in ipairs {
  "functions",
  "objects",
  "reroller",
  "ui",
} do
  load_dir(path, "src/")
end

-- Load config page
assert(SMODS.load_file("src/config_page.lua"))()