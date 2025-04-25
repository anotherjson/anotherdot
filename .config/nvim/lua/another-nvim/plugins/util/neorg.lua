-- https://github.com/nvim-neorg/neorg/wiki/Default-Keybinds
return {
	"nvim-neorg/neorg",
	lazy = true,
	ft = { "norg" },
	version = "*",
	config = function()
		require("neorg").setup({
			load = {
				["core.defaults"] = {},
				["core.completion"] = {
					config = {
						engine = "nvim-cmp",
					},
				},
				["core.export.markdown"] = {},
				["core.presenter"] = {
					config = {
						zen_mode = "zen-mode",
					},
				},
				["core.summary"] = {},
				["core.concealer"] = {},
				["core.dirman"] = {
					config = {
						workspaces = {
							notes = "~/notes",
						},
						default_workspace = "notes",
					},
				},
			},
		})
		vim.wo.foldlevel = 99
		vim.wo.conceallevel = 2
		vim.keymap.set("n", "<localleader>nt", { desc = "Create New Today Entry" })
	end,
}
