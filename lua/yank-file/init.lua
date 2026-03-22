local yank_file = {}

local defaults = {
  keymap = "Y",
  use_full_path = false,
  register = "+",
  notify = true,
}

yank_file.config = vim.deepcopy(defaults)

local function merged_config(opts)
  return vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

local function notify(msg, level)
  if not yank_file.config.notify then
    return
  end

  vim.notify(msg, level or vim.log.levels.INFO, {
    title = "debug_yank_file"
  })
end

local function get_node()
  local ok, api = pcall(require, "nvim-tree.api")
  if not ok then
    notify("nvim-tree not found", vim.log.levels.ERROR)
    return nil, nil
  end

  local node = api.tree.get_node_under_cursor()
  if not node then
    notify("No file under cursor", vim.log.levels.WARN)
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

  local name = yank_file.config.use_full_path and path or (node.name or vim.fn.fnamemodify(path, ":t"))
  local payload = ("File: %s\n\n%s"):format(name, content)

  vim.fn.setreg(yank_file.config.register, payload)
  vim.fn.setreg('"', payload)
end

function yank_file.on_attach(bufnr)
  local ok, api = pcall(require, "nvim-tree.api")
  if not ok then
    notify("nvim-tree.api not found", vim.log.levels.ERROR)
    return
  end

  api.config.mappings.default_on_attach(bufnr)

  vim.keymap.set("n", yank_file.config.keymap, yank_file.copy, {
    buffer = bufnr,
    noremap = true,
    silent = true,
    desc = "Copy file name and full file contents",
  })
end

function yank_file.setup(opts)
  yank_file.config = merged_config(opts)

  local ok, nvim_tree = pcall(require, "nvim-tree")
  if not ok then
    notify("nvim-tree plugin not found", vim.log.levels.ERROR)
    return
  end

  nvim_tree.setup({
    on_attach = yank_file.on_attach,
  })
end

return yank_file

