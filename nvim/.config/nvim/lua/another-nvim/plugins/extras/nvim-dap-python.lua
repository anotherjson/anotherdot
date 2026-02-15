return {
	"mfussenegger/nvim-dap-python",
	dependencies = {
		"mfussenegger/nvim-dap",
		"linux-cultist/venv-selector.nvim",
	},
	lazy = true,
	ft = "python",
	keys = {
		{
			"<leader>dtm",
			function()
				require("dap-python").test_method()
			end,
			desc = "DAP Python: Debug test method",
			ft = "python",
		},
		{
			"<leader>dtc",
			function()
				require("dap-python").test_class()
			end,
			desc = "DAP Python: Debug test class",
			ft = "python",
		},
		{
			"<leader>dS",
			function()
				require("dap-python").debug_selection()
			end,
			mode = "v",
			desc = "DAP Python: Debug selection",
			ft = "python",
		},
	},
	config = function()
		-- Use Mason's debugpy installation
		local mason_path = vim.fn.stdpath("data") .. "/mason/packages"
		local debugpy_path = mason_path .. "/debugpy/venv/bin/python"

		-- Initialize dap-python with Mason's debugpy
		require("dap-python").setup(debugpy_path)

		local dap = require("dap")

		-- Hook into venv-selector to update Python path when venv changes
		-- This is the KEY integration that fixes venv issues
		vim.api.nvim_create_autocmd("User", {
			pattern = "VenvSelectPost",
			callback = function()
				local venv_python = require("venv-selector").venv_python
				if venv_python then
					-- Update all Python configurations to use the selected venv
					for _, config in ipairs(dap.configurations.python or {}) do
						config.python = venv_python
						config.pythonPath = venv_python
					end
					print("DAP Python path updated to: " .. venv_python)
				end
			end,
			desc = "Update DAP Python path when venv changes",
		})

		-- Enhanced Python configurations
		dap.configurations.python = {
			{
				type = "python",
				request = "launch",
				name = "Launch file",
				program = "${file}",
				pythonPath = function()
					-- Try to get venv-selector's Python first
					local venv_python = require("venv-selector").venv_python
					if venv_python and venv_python ~= "" then
						return venv_python
					end
					-- Fallback to debugpy's Python
					return debugpy_path
				end,
				console = "integratedTerminal",
			},
			{
				type = "python",
				request = "launch",
				name = "Launch file with arguments",
				program = "${file}",
				args = function()
					local args_string = vim.fn.input("Arguments: ")
					return vim.split(args_string, " +")
				end,
				pythonPath = function()
					local venv_python = require("venv-selector").venv_python
					if venv_python and venv_python ~= "" then
						return venv_python
					end
					return debugpy_path
				end,
				console = "integratedTerminal",
			},
			{
				type = "python",
				request = "attach",
				name = "Attach remote",
				connect = function()
					local host = vim.fn.input("Host [127.0.0.1]: ")
					host = host ~= "" and host or "127.0.0.1"
					local port = tonumber(vim.fn.input("Port [5678]: ")) or 5678
					return { host = host, port = port }
				end,
			},
			{
				type = "python",
				request = "launch",
				name = "Run pytest (current file)",
				module = "pytest",
				args = {
					"${file}",
					"-v",
					"-s",
				},
				pythonPath = function()
					local venv_python = require("venv-selector").venv_python
					if venv_python and venv_python ~= "" then
						return venv_python
					end
					return debugpy_path
				end,
				console = "integratedTerminal",
				justMyCode = false,
			},
			{
				type = "python",
				request = "launch",
				name = "Run pytest (all tests)",
				module = "pytest",
				args = {
					"-v",
					"-s",
				},
				pythonPath = function()
					local venv_python = require("venv-selector").venv_python
					if venv_python and venv_python ~= "" then
						return venv_python
					end
					return debugpy_path
				end,
				console = "integratedTerminal",
				justMyCode = false,
			},
			{
				type = "python",
				request = "launch",
				name = "Debug Django",
				program = vim.fn.getcwd() .. "/manage.py",
				args = {
					"runserver",
					"--noreload",
				},
				pythonPath = function()
					local venv_python = require("venv-selector").venv_python
					if venv_python and venv_python ~= "" then
						return venv_python
					end
					return debugpy_path
				end,
				console = "integratedTerminal",
				justMyCode = false,
			},
		}

		-- Test method debugging (for pytest)
		require("dap-python").test_runner = "pytest"
	end,
}
