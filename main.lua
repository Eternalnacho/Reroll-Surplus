
RerollSurplus = {
  FUNCS = {},
  UIDEF = {},
  UI = {},

  config = SMODS.current_mod.config
}

-- Get directory loader
local load_dir, load_folders = assert(SMODS.load_file("src/loader.lua"))()

-- Load directories
for _, path in ipairs {
  "src/functions",
  "src/reroller",
} do
  load_dir(path)
end

-- Load config page
assert(SMODS.load_file("src/config_page.lua"))()