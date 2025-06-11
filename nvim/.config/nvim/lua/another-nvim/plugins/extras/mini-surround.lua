-- Fast and feature-rich surround actions. For text that includes
-- surrounding characters like brackets or quotes, this allows you
-- to select the text inside, change or modify the surrounding characters,
-- and more.
return {
	"echasnovski/mini.surround",
	lazy = true,
	event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
	recommended = true,
	opts = {
		mappings = {
			add = "<leader>sa", -- Add surrounding in Normal and Visual modes
			delete = "<leader>sd", -- Delete surrounding
			find = "<leader>sf", -- Find surrounding (to the right)
			find_left = "<leader>sF", -- Find surrounding (to the left)
			highlight = "<leader>s/", -- Highlight surrounding
			replace = "<leader>sr", -- Replace surrounding
			update_n_lines = "<leader>sn", -- Update `n_lines`
		},
	},
}
