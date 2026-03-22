local yank_file = {}

local defaults = {
  copy_keymap = "Y",
  paste_keymap = "P",
  debug = false,
}

yank_file.config = vim.deepcopy(defaults)

yank_file.state = {
  copied_file = nil,
}

function yank_file.setup(opts)
  yank_file.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

local function notify(msg, level)
  if not yank_file.config.notify then
    return
  end

  vim.notify(msg, level or vim.log.levels.INFO, {
    title = "yank_file",
  })
end

local function get_node()
  local ok, api = pcall(require, "nvim-tree.api")
  if not ok then
    notify("nvim-tree.api not found", vim.log.levels.ERROR)
    return nil, nil
  end

  local node = api.tree.get_node_under_cursor()
  if not node then
    notify("No node under cursor", vim.log.levels.WARN)
    return nil, api
  end

  return node, api
end

local function read_file(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil, ("Could not read file: %s"):format(path)
  end

  return table.concat(lines, "\n"), nil
end

local function write_file(path, content)
  local dir = vim.fn.fnamemodify(path, ":h")
  if dir ~= "." then
    vim.fn.mkdir(dir, "p")
  end

  local lines = {}
  if content ~= "" then
    lines = vim.split(content, "\n", { plain = true })
  end

  local ok, err = pcall(vim.fn.writefile, lines, path)
  if not ok then
    return nil, ("Could not write file: %s (%s)"):format(path, err or "unknown error")
  end

  return true
end

local function get_target_dir(node)
  if node.type == "directory" then
    return node.absolute_path
  end

  if node.type == "file" then
    return vim.fn.fnamemodify(node.absolute_path, ":h")
  end

  return nil
end

function yank_file.copy()
  local node = get_node()
  if not node then
    return
  end

  if node.type ~= "file" then
    notify("Selected node is not a file", vim.log.levels.WARN)
    return
  end

  local path = node.absolute_path
  if not path or path == "" then
    notify("Could not resolve file path", vim.log.levels.ERROR)
    return
  end

  local content, err = read_file(path)
  if err then
    notify(err, vim.log.levels.ERROR)
    return
  end

  yank_file.state.copied_file = {
    fileName = node.name or vim.fn.fnamemodify(path, ":t"),
    content = content,
  }
end

function yank_file.paste()
  local node, api = get_node()
  if not node then
    return
  end

  local copied = yank_file.state.copied_file
  if not copied then
    notify("No copied file available", vim.log.levels.WARN)
    return
  end

  local target_dir = get_target_dir(node)
  if not target_dir or target_dir == "" then
    notify("Could not determine target directory", vim.log.levels.ERROR)
    return
  end

  local dest_path = vim.fs.joinpath(target_dir, copied.fileName)

  if vim.fn.filereadable(dest_path) == 1 then
    notify(("File already exists: %s"):format(dest_path), vim.log.levels.WARN)
    return
  end

  local ok, err = write_file(dest_path, copied.content)
  if not ok then
    notify(err, vim.log.levels.ERROR)
    return
  end

  if api and api.tree and api.tree.reload then
    api.tree.reload()
  end
end

function yank_file.on_attach(bufnr)
  vim.keymap.set("n", yank_file.config.copy_keymap, yank_file.copy, {
    buffer = bufnr,
    noremap = true,
    silent = true,
    desc = "Copy file name and file contents",
  })

  vim.keymap.set("n", yank_file.config.paste_keymap, yank_file.paste, {
    buffer = bufnr,
    noremap = true,
    silent = true,
    desc = "Paste copied file into current directory",
  })
end

return yank_file
