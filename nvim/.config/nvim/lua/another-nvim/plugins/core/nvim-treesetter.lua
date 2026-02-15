return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		local configs = require("nvim-treesitter.configs")

		configs.setup({
			ensure_installed = {
				-- Essential
				"vim",
				"vimdoc",
				"lua",
				"query",

				-- Actively used languages
				"python",
				"go",
				"javascript",
				"typescript",
				"sql",
				"bash",
				"c",
				"rust",
				"svelte",

				-- Markup/Config
				"markdown",
				"json",
				"yaml",
				"toml",
				"html",
				"css",

				-- Git
				"git_config",
				"git_rebase",
				"gitcommit",
				"gitignore",
				"gitattributes",

				-- Data/DevOps
				"csv",
				"dockerfile",
				"terraform",

				-- Note-taking
				"norg",

				-- Other
				"diff",
				"regex",
			},
			sync_install = false,
			auto_install = true,
			highlight = { enable = true, additional_vim_regex_highlighting = false },
			indent = { enable = true },
		})
	end,
}
