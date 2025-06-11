return {
	"folke/zen-mode.nvim",
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
		keymaps = {
			vim.keymap.set("n", "<leader>zm", vim.cmd.ZenMode, { desc = "Momement of zen" }),
		},
	},
}
