# nvim

Neovim config built on [`lazy.nvim`], structured under
`lua/another-nvim/`. Drop the package via `dots stow nvim` (links
`.config/nvim` into `~/.config/nvim`).

[`lazy.nvim`]: https://github.com/folke/lazy.nvim

## Init order

```
init.lua
  └─ require("another-nvim.config")  → config/keymaps.lua, config/options.lua
  └─ require("another-nvim.lazy")    → bootstrap lazy.nvim, then load plugin specs
       └─ plugins/core    (colorscheme, telescope, treesitter, plenary, web-devicons)
       └─ plugins/util    (cmp, lualine, bufferline, conform, which-key, …)
       └─ plugins/extras  (dap, dadbod, diffview, harpoon, neogit, noice, …)
       └─ plugins/lsp/mason
       └─ plugins/lsp/nvim-lspconfig
```

## Adding a plugin

Drop a new spec file under `plugins/extras/` (or `core`/`util` if it fits a
category). Lazy auto-imports the directory — no central registry to update.
Spec format is the standard lazy.nvim table:

```lua
return {
  "owner/repo",
  opts = { ... },
}
```

After adding, run `:Lazy sync` to install.

## LSP & tooling

Servers and CLI tools are managed by [`mason.nvim`] via
`plugins/lsp/mason.lua`:

- **LSP servers** (`mason-lspconfig.ensure_installed`): `lua_ls`, `pylsp`,
  `bashls`, `ts_ls`, `svelte`
- **Formatters/linters** (`mason-tool-installer`): `prettier`, `stylua`,
  `black`, `pylint`, `debugpy`, `selene`, `sqlfmt`, `sqlfluff`, `eslint_d`,
  `xmlformatter`, `beautysh`, `shellcheck`

Add a server: append to `ensure_installed` in `mason.lua`, then add the
matching `lspconfig` setup block in `nvim-lspconfig.lua`.

[`mason.nvim`]: https://github.com/williamboman/mason.nvim

## Colorscheme

Pinned to [`craftzdog/solarized-osaka.nvim`] in
`plugins/core/colorscheme.lua`. The `lazy.setup` call hard-references it as
the install-time colorscheme, so don't rename without updating both.

[`craftzdog/solarized-osaka.nvim`]: https://github.com/craftzdog/solarized-osaka.nvim

## External system deps

Mason installs LSP servers but several plugins shell out to OS binaries.
Install on Arch:

```zsh
yay -S ripgrep fd fzf tree-sitter-cli
```

For Python tooling (debugpy, pytest, etc.) you'll want a `neovim` pyenv
virtualenv — see [`../guides/arch.md`](../guides/arch.md) for the install
sequence.
