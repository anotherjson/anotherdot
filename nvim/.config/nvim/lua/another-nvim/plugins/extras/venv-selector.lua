return {
	"linux-cultist/venv-selector.nvim",
	dependencies = {
		"neovim/nvim-lspconfig",
		"mfussenegger/nvim-dap",
		"mfussenegger/nvim-dap-python", --optional
		{ "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },
	},
	lazy = false, -- Optional: needed only if you want to type `:VenvSelect` without a keymapping
	branch = "regexp",
	config = function()
		require("venv-selector").setup({
			-- Your options go here
			-- name = "venv",
			-- auto_refresh = false
			auto_refresh = true,
			dap_enabled = true,
			poetry_path = "~/Library/Caches/pypoetry/virtualenvs",
		})
	end,
	keys = {
		-- Keymap to open VenvSelector to pick a venv.
		{ "<leader>vs", "<cmd>VenvSelect<cr>" },
		-- Keymap to retrieve the venv from a cache (the one previously used for the same project directory).
		{ "<leader>vc", "<cmd>VenvSelectCached<cr>" },
	},
}
