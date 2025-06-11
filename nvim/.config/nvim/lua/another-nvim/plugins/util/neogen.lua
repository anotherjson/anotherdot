return {
	"danymat/neogen",
	lazy = true,
	event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
	-- config = true,
	-- Uncomment next line if you want to follow only stable versions
	-- version = "*"
	config = function()
		local neogen = require("neogen")

		neogen.setup({
			enabled = true, --if you want to disable Neogen
			input_after_comment = true,
			snippet_engine = "luasnip",
			opts = {
				noremap = true,
				silent = true,
			},
			vim.api.nvim_set_keymap(
				"n",
				"<leader>nf",
				":lua require('neogen').generate()<CR>",
				{ desc = "Neogen generate" }
			),
		})
	end,
}
