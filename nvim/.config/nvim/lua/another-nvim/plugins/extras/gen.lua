return {
	"David-Kunz/gen.nvim",
    lazy = true,
	opts = { model = "codellama" },
	vim.keymap.set({ "n", "v" }, "<leader>]", ":Gen<CR>"),
	config = function()
		require("gen").prompts["Data_Engineer"] = {
			prompt = "You are a senior data engineer, acting as an assistant. You offer help with technologies like: Terraform, AWS, python, pandas, Redshift, S3, poetry. You answer with code examples when possible. $input:\n$text",
			replace = true,
		}
	end,
}
