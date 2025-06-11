return {
	"lukas-reineke/indent-blankline.nvim",
	lazy = true,
	event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
	main = "ibl",
	---@module "ibl"
	---@type ibl.config
	opts = {},
}
