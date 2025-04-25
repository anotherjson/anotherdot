return {
	"MagicDuck/grug-far.nvim",
	lazy = false,
	config = function()
		require("grug-far").setup({
			-- options, see Configuration section below
			-- there are no required options atm
			-- engine = 'ripgrep' is default, but 'astgrep' can be specified
			opts = {
				-- shortcuts for the actions you see at the top of the buffer
				-- set to '' or false to unset. Mappings with no normal mode value will be removed from the help header
				-- you can specify either a string which is then used as the mapping for both normal and insert mode
				-- or you can specify a table of the form { [mode] = <lhs> } (ex: { i = '<C-enter>', n = '<localleader>gr'})
				-- it is recommended to use <localleader> though as that is more vim-ish
				-- see https://learnvimscriptthehardway.stevelosh.com/chapters/11.html#local-leader
				keymaps = {
					replace = { n = "<localleader>r" },
					qflist = { n = "<localleader>q" },
					syncLocations = { n = "<localleader>s" },
					syncLine = { n = "<localleader>l" },
					close = { n = "<localleader>c" },
					historyOpen = { n = "<localleader>t" },
					historyAdd = { n = "<localleader>a" },
					refresh = { n = "<localleader>f" },
					openLocation = { n = "<localleader>o" },
					openNextLocation = { n = "<down>" },
					openPrevLocation = { n = "<up>" },
					gotoLocation = { n = "<enter>" },
					pickHistoryEntry = { n = "<enter>" },
					abort = { n = "<localleader>b" },
					help = { n = "g?" },
					toggleShowCommand = { n = "<localleader>p" },
					swapEngine = { n = "<localleader>e" },
					previewLocation = { n = "<localleader>i" },
					swapReplacementInterpreter = { n = "<localleader>x" },
				},
			},
		})
	end,
}
