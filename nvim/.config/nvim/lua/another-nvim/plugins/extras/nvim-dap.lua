return {
	"mfussenegger/nvim-dap",
	lazy = true,
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"theHamsta/nvim-dap-virtual-text",
	},
	keys = {
		{
			"<F5>",
			function()
				require("dap").continue()
			end,
			desc = "DAP: Continue/Start debugging",
		},
		{
			"<F10>",
			function()
				require("dap").step_over()
			end,
			desc = "DAP: Step over",
		},
		{
			"<F11>",
			function()
				require("dap").step_into()
			end,
			desc = "DAP: Step into",
		},
		{
			"<F12>",
			function()
				require("dap").step_out()
			end,
			desc = "DAP: Step out",
		},
		{
			"<leader>db",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "DAP: Toggle breakpoint",
		},
		{
			"<leader>dB",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			desc = "DAP: Set conditional breakpoint",
		},
		{
			"<leader>dL",
			function()
				require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
			end,
			desc = "DAP: Set log point",
		},
		{
			"<leader>dc",
			function()
				require("dap").clear_breakpoints()
			end,
			desc = "DAP: Clear all breakpoints",
		},
		{
			"<leader>dr",
			function()
				require("dap").repl.toggle()
			end,
			desc = "DAP: Toggle REPL",
		},
		{
			"<leader>dl",
			function()
				require("dap").run_last()
			end,
			desc = "DAP: Run last debug session",
		},
		{
			"<leader>dt",
			function()
				require("dap").terminate()
			end,
			desc = "DAP: Terminate debug session",
		},
		{
			"<leader>dp",
			function()
				require("dap").pause()
			end,
			desc = "DAP: Pause execution",
		},
	},
	config = function()
		local dap = require("dap")

		-- DAP signs in the gutter
		vim.fn.sign_define("DapBreakpoint", {
			text = "●",
			texthl = "DapBreakpoint",
			linehl = "",
			numhl = "",
		})
		vim.fn.sign_define("DapBreakpointCondition", {
			text = "◆",
			texthl = "DapBreakpointCondition",
			linehl = "",
			numhl = "",
		})
		vim.fn.sign_define("DapLogPoint", {
			text = "◆",
			texthl = "DapLogPoint",
			linehl = "",
			numhl = "",
		})
		vim.fn.sign_define("DapStopped", {
			text = "→",
			texthl = "DapStopped",
			linehl = "DapStoppedLine",
			numhl = "",
		})
		vim.fn.sign_define("DapBreakpointRejected", {
			text = "○",
			texthl = "DapBreakpointRejected",
			linehl = "",
			numhl = "",
		})

		-- Set colors for DAP signs
		vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400" })
		vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#f79000" })
		vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef" })
		vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379" })
		vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#31353f" })
		vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#5c6370" })

		-- DAP configurations will be set by language-specific plugins (nvim-dap-python, etc.)
	end,
}
