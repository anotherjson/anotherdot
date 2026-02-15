return {
	"David-Kunz/gen.nvim",
	opts = { model = "gemma3n:e4b" },
	vim.keymap.set({ "n", "v" }, "<leader>]", ":Gen<CR>"),
	config = function()
		require("gen").prompts["Data_Engineer"] = {
			prompt = "You are a senior data engineer, acting as an assistant. You offer help with technologies like: Terraform, AWS, python, pandas, Redshift, S3, uv, dagster, dbt. You answer with code examples when possible. $input:\n$text",
			replace = true,
		}
		require("gen").prompts["DUCKDB_SQL"] = {
			prompt = "You are a senior analytics engineer, acting as an assistant. You offer help with technologies like: dbt, dagster, python, and :q. You answer with code examples when possible. $input:\n$text",
			replace = true,
			model = "duckdb-nsql:latest",
		}
		require("gen").prompts["SQL_Coder"] = {
			prompt = "You are a senior analytics engineer, acting as an assistant. You offer help with technologies like: dbt, dagster, python, and :q. You answer with code examples when possible. $input:\n$text",
			replace = true,
			model = "sqlcoder:latest",
		}
	end,
}
