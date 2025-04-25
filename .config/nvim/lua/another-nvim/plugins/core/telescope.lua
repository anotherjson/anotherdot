return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
		"nvim-telescope/telescope-live-grep-args.nvim",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local builtin = require("telescope.builtin")
		local lga_actions = require("telescope-live-grep-args.actions")
		local live_grep_args_shortcuts = require("telescope-live-grep-args.shortcuts")
		local keymap = vim.keymap -- for conciseness

		telescope.load_extension("fzf")
		telescope.setup({
			defaults = {
				path_display = { "truncate " },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous, -- move to prev result
						["<C-j>"] = actions.move_selection_next, -- move to next result
						--["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
					},
				},
			},
			extensions = {
				live_grep_args = {
					auto_quoting = true, -- enable/disable auto-quoting
					-- define mappings, e.g.
					mappings = { -- extend mappings
						i = {
							["<C-k>"] = lga_actions.quote_prompt(),
							["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
							-- freeze the current list and start a fuzzy search in the frozen list
							["<C-space>"] = actions.to_fuzzy_refine,
						},
					},
				},
			},
		})
		telescope.load_extension("live_grep_args")
		-- set keymaps
		keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
		keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
		keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
		keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })
		keymap.set("n", "<leader>fb", builtin.find_files, { desc = "Fuzzy find files in cwd the with builtin" })
		keymap.set("n", "<leader>fg", builtin.git_files, { desc = "Fuzzy find git files" })
		keymap.set("n", "<leader>f>", function()
			builtin.grep_string({ search = vim.fn.input("Grep > ") })
		end, { desc = "Grep find" })
		keymap.set(
			"n",
			"<leader>fas",
			":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
			{ desc = "Find string with args" }
		)
		keymap.set(
			"n",
			"<leader>fac",
			live_grep_args_shortcuts.grep_word_under_cursor,
			{ desc = "Find string with args under cursor" }
		)
		keymap.set(
			"n",
			"<leader>fax",
			live_grep_args_shortcuts.grep_word_under_cursor_current_buffer,
			{ desc = "Find string with args under cursor in buffer" }
		)
		keymap.set(
			"v",
			"<leader>fav",
			live_grep_args_shortcuts.grep_visual_selection,
			{ desc = "Find selection with args" }
		)
		keymap.set(
			"v",
			"<leader>fab",
			live_grep_args_shortcuts.grep_word_visual_selection_current_buffer,
			{ desc = "Find selection with args in buffer" }
		)
	end,
}
