return {
	"folke/todo-comments.nvim",
	lazy = true,
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
		keymaps = {
			vim.keymap.set("n", "<leader>on", function()
				require("todo-comments").jump_next()
			end, { desc = "Next todo comment" }),

			vim.keymap.set("n", "<leader>op", function()
				require("todo-comments").jump_prev()
			end, { desc = "Previous todo comment" }),
		},
	},
}
