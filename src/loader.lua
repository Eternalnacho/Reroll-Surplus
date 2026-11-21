local dir_index = {
  ['functions'] = {
    "utils.lua",
    "ui.lua",
    "inputmanager.lua",
    "buttons.lua",
    "number_input.lua"
  },
}

local function load_directory_from_index(path, prefix)
  for _, file in ipairs(dir_index[path]) do
    assert(SMODS.load_file(prefix .. path .. '/' .. file))()
  end
end

local function load_directory(path, prefix)
  if dir_index[path] then
    load_directory_from_index(path, prefix)
  else
    local files = NFS.getDirectoryItems(SMODS.current_mod.path .. prefix .. path)
    for _, file_path in ipairs(files) do
      local file_type = NFS.getInfo(SMODS.current_mod.path .. prefix .. path .. '/' .. file_path).type

      if file_type == "directory" then
        load_directory(path .. '/' .. file_path, prefix)
      elseif file_type ~= "symlink" then
        assert(SMODS.load_file(prefix .. path .. '/' .. file_path))()
      end
    end
  end
end

return load_directory