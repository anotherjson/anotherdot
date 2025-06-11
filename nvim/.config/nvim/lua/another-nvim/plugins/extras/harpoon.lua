return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	lazy = false,
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local harpoon = require("harpoon")
		local keymap = vim.keymap

		harpoon.setup(
			keymap.set("n", "<leader>hf", function()
				harpoon:list():add()
			end, { desc = "Mark file with harpoon" }),
			keymap.set("n", "<leader>hh", function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end, { desc = "Go to harpoon quick menu" }),
			keymap.set("n", "<leader>hj", function()
				harpoon:list():select(1)
			end, { desc = "Go to harpoon mark 1" }),
			keymap.set("n", "<leader>hk", function()
				harpoon:list():select(2)
			end, { desc = "Go to harpoon mark 2" }),
			keymap.set("n", "<leader>hl", function()
				harpoon:list():select(1)
			end, { desc = "Go to harpoon mark 3" }),
			keymap.set("n", "<leader>h;", function()
				harpoon:list():select(4)
			end, { desc = "Go to harpoon mark 4" })
		)
	end,
}
