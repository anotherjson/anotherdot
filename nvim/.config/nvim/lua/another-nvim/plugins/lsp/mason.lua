return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- import mason
		local mason = require("mason")

		-- import mason-lspconfig
		local mason_lspconfig = require("mason-lspconfig")

		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		mason_lspconfig.setup({
			-- list of servers for mason to install
			ensure_installed = {
				"lua_ls",
				"sqlls",
				"pylsp",
				"bashls",
				"gopls",
				"ts_ls",
				"svelte",
			},
			-- auto-install configured servers (with lspconfig)
			automatic_installation = true, -- not the same as ensure_installed
		})

		mason_tool_installer.setup({
			ensure_installed = {
				"prettier", -- prettier formatter
				"stylua", -- lua formatter
				"black", -- python formatter
				"gofumpt", -- go formatter
				"pylint", -- python linter
				"debugpy", -- python debugger
				"selene", -- lua linter
				"sqlfmt", -- sql formatter
				"sqlfluff", -- sql linter
				"golangci-lint", -- go linter (meta-linter with 50+ linters)
				"eslint_d", -- javascript/typescript linter (daemon mode)
				"xmlformatter", -- xml formatter
				"beautysh", -- bash formatter
				"shellcheck", -- bash linter
				"delve", -- go debugger
			},
		})
	end,
}
