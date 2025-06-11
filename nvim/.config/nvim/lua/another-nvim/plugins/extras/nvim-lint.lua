return {
	"mfussenegger/nvim-lint",
	lazy = true,
	event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
	config = function()
		local lint = require("lint")
		local api = vim.api
		local keymap = vim.keymap

		lint.linters_by_ft = {
			lua = { "selene" },
			python = { "pylint" },
			sql = { "sqlfluff" },
		}

		local lint_augroup = api.nvim_create_augroup("lint", { clear = true })

		api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})

		keymap.set("n", "<leader>ll", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })

		lint.linters.pylint.cmd = "python"
		lint.linters.pylint.args = { "-m", "pylint", "-f", "json" }
	end,
}
