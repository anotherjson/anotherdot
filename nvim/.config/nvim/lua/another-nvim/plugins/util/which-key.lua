return {
	"folke/which-key.nvim",
	opts = {
		spec = {
			{ "<BS>", desc = "Decrement Selection", mode = "x" },
			{ "<c-space>", desc = "Increment Selection", mode = { "x", "n" } },

			-- DAP key groups
			-- { "<leader>d", group = "Debug (DAP)" },
			-- { "<leader>dt", group = "Debug Tests" },
			-- { "<F5>", desc = "Debug: Continue" },
			-- { "<F10>", desc = "Debug: Step Over" },
			-- { "<F11>", desc = "Debug: Step Into" },
			-- { "<F12>", desc = "Debug: Step Out" },
		},
	},
}
