# yank_file.nvim

Copy a file and its contents from `nvim-tree`, then paste it elsewhere inside the tree.

## What this plugin does

- Copy any file from the current cursor position in `nvim-tree` using `Y[default]`.
- Stores the copied file_name and the contents in the memory.
- Paste it into any directory inside the `nvim-tree` using `P[default]`.

## Deps

- Neovim >= 0.8
- [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua)

## Usage

Inside your `nvim-tree`:

- Press `Y` on any file to copy its name and its contents.
- Move to any directory or file inside `nvim-tree`.
- Press `P` to paste all of it.

Paste behavior:

- If the cursor is on a directory, the paste will be inside that directory.
- If the cursor is on a file, the paste will be on the parent directory of the file.

## Default config

```lua
require("yank_file").setup({
  copy_keymap = "Y",
  paste_keymap = "P",
  debug = true,
})
```

## Installation

#### LazyVim

```lua
{
  "mani-arjunan/yank-file.nvim",
  dependencies = { "nvim-tree/nvim-tree.lua" },
  config = function()
    require("yank-file").setup({
      copy_keymap = "Y",
      paste_keymap = "P",
    })
  end,
}
```

#### Packer

```lua
use({
  "mani-arjunan/yank-file.nvim",
  requires = { "nvim-tree/nvim-tree.lua" },
  config = function()
    require("yank-file").setup({
      copy_keymap = "Y",
      paste_keymap = "P",
    })
  end,
})
```

#### Setup

```lua
local function custom_on_attach(bufnr)
  local api = require("nvim-tree.api")

  api.config.mappings.default_on_attach(bufnr)
  require("yank_file").on_attach(bufnr)
end

require("nvim-tree").setup({
  on_attach = custom_on_attach,
})
```
