return {
	"NeogitOrg/neogit",
	--lazy = true,
	dependencies = {
		"nvim-lua/plenary.nvim", -- required
		"sindrets/diffview.nvim", -- optional - Diff integration
		"nvim-telescope/telescope.nvim", -- optional
	},
	config = function()
		local keymap = vim.keymap
		local neogit = require("neogit")
		neogit.setup({
			keymap.set("n", "<leader>gs", neogit.open, { silent = true, noremap = true }),
		})
	end,
}
