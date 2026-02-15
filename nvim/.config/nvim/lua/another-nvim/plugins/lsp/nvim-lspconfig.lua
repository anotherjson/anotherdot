return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	config = function()
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local keymap = vim.keymap
		local lsp = vim.lsp
		local diagnostic = vim.diagnostic
		local fn = vim.fn
		local api = vim.api

		local opts = { noremap = true, silent = true }
		local on_attach = function(client, bufnr)
			opts.buffer = bufnr

			-- set keybinds
			opts.desc = "Show LSP references"
			keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

			opts.desc = "Go to declaration"
			keymap.set("n", "gD", lsp.buf.declaration, opts)

			opts.desc = "Show LSP definitions"
			keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

			opts.desc = "Show LSP implementations"
			keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

			opts.desc = "Show LSP type definitions"
			keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

			opts.desc = "See available code actions"
			keymap.set({ "n", "v" }, "<leader>ca", lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

			opts.desc = "Smart rename"
			keymap.set("n", "<leader>rn", lsp.buf.rename, opts) -- smart rename

			opts.desc = "Show buffer diagnostics"
			keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

			opts.desc = "Show line diagnostics"
			keymap.set("n", "<leader>d", diagnostic.open_float, opts) -- show diagnostics for line

			opts.desc = "Go to previous diagnostic"
			keymap.set("n", "[d", diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

			opts.desc = "Go to next diagnostic"
			keymap.set("n", "]d", diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

			opts.desc = "Show documentation for what is under cursor"
			keymap.set("n", "K", lsp.buf.hover, opts) -- show documentation for what is under cursor

			opts.desc = "Restart LSP"
			keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary

			if client.name == "svelte" then
				api.nvim_create_autocmd("BufWritePost", {
					pattern = { "*.js", "*.ts" },
					group = api.nvim_create_augroup("svelte_ondidchange", { clear = true }),
					callback = function(ctx)
						client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
					end,
				})
			end
		end

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Change the Diagnostic symbols in the sign column (gutter)
		-- (not in youtube nvim video)
		diagnostic.config({
			signs = {
				text = {
					[diagnostic.severity.ERROR] = " ",
					[diagnostic.severity.WARN] = " ",
					[diagnostic.severity.HINT] = "󰠠 ",
					[diagnostic.severity.INFO] = " ",
				},
			},
		})

		-- Lua language server
		lsp.config("lua_ls", {
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					workspace = {
						library = {
							[fn.expand("$VIMRUNTIME/lua")] = true,
							[fn.stdpath("config") .. "/lua"] = true,
						},
					},
				},
			},
		})

		-- Python language server
		lsp.config("pylsp", {
			filetypes = { "python" },
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				pylsp = {
					plugins = {
						black = {
							enabled = true,
							line_length = 88,
						},
						pylint = {
							enabled = true,
							executable = "pylint",
							args = { "--max-line-length=88" },
						},
						pycodestyle = {
							maxLineLength = 88,
						},
					},
				},
			},
		})

		-- Go language server
		lsp.config("gopls", {
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				gopls = {
					analyses = {
						unusedparams = true,
						shadow = true,
					},
					gofumpt = true,
				},
			},
		})

		-- SQL language server
		lsp.config("sqlls", {
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- Bash language server
		lsp.config("bashls", {
			capabilities = capabilities,
			on_attach = on_attach,
		})

		lsp.config("ts_ls", {
			init_options = {
				preferences = {
					disableSuggestions = true,
				},
			},
			capabilities = capabilities,
			on_attach = on_attach,
		})

		lsp.config("svelte", {
			init_options = {
				configuration = {
					svelte = {
						plugin = {
							svelte = { enable = true },
							css = { enable = true },
							html = { enable = true },
						},
					},
				},
			},
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- Enable the configured servers
		local servers = { "lua_ls", "pylsp", "gopls", "ts_ls", "svelte", "sqlls", "bashls" }
		for _, server in ipairs(servers) do
			lsp.enable(server)
		end
	end,
}
