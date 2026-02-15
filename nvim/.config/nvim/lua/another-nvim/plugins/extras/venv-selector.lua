return {
	"linux-cultist/venv-selector.nvim",
	dependencies = {
		"neovim/nvim-lspconfig",
		"mfussenegger/nvim-dap",
		"mfussenegger/nvim-dap-python", --optional
		{ "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },
	},
	lazy = true, -- Lazy load on keymap (loads on <leader>vs or <leader>vc)
	-- branch = "regexp",
	config = function()
		require("venv-selector").setup({
			-- Your options go here
			-- name = "venv",
			-- auto_refresh = false
			auto_refresh = true,
			dap_enabled = true,
			poetry_path = "~/Library/Caches/pypoetry/virtualenvs",

			-- Notify on venv change (allows other plugins to react)
			changed_venv_hooks = {
				function(venv_path, venv_python)
					-- Trigger custom event that DAP will listen to
					vim.api.nvim_exec_autocmds("User", { pattern = "VenvSelectPost" })
				end,
			},
		})
	end,
	keys = {
		-- Keymap to open VenvSelector to pick a venv.
		{ "<leader>vs", "<cmd>VenvSelect<cr>" },
		-- Keymap to retrieve the venv from a cache (the one previously used for the same project directory).
		{ "<leader>vc", "<cmd>VenvSelectCached<cr>" },
	},
}
