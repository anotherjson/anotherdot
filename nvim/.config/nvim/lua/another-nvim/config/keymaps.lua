-- set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- for conciseness
local keymap = vim.keymap
local api = vim.api
local cmd = vim.cmd

-- getting out of the buffer
keymap.set("n", "<leader>qq", cmd.Ex, { desc = "Exit buffer" })
keymap.set("n", "<leader>qww", cmd.wq, { desc = "Quit with write" })
keymap.set("n", "<leader>qwa", cmd.wqa, { desc = "Quit with write all" })
keymap.set("n", "<leader>qu", cmd.wq, { desc = "Quit without save" })

-- some file changes to do in normal mode
api.nvim_set_keymap("n", "[[", "^", { noremap = false, desc = "Go to begining of line" })
api.nvim_set_keymap("n", "]]", "$", { noremap = false, desc = "Go to end of line" })

-- moving around in visual
keymap.set("v", "K", ":m '>+1<CR>gv=gv", { desc = "Move command visual up" })
keymap.set("v", "J", ":m '<-2<CR>gv=gv", { desc = "Move command visual down" })

-- moving around normal
keymap.set("n", "J", "mzJ`z", { desc = "Append current line with space" })
keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Half page jump down" })
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Half page jump up" })
keymap.set("n", "n", "nzzzv", { desc = "Search terms next" })
keymap.set("n", "N", "Nzzzv", { desc = "Search terms back" })

-- next greatest remap ever : asbjornHaland
keymap.set({ "n", "v" }, "<leader>ys", [["+y]], { desc = "Copy to sys clipboard" })
keymap.set({ "n", "v" }, "<leader>Ys", [["+Y]], { desc = "Copy to end of line to sys clipboard" })
keymap.set({ "n", "v" }, "<leader>ds", [["_d]], { desc = "Delete to sys clipboard" })

-- to avoid hell
keymap.set("n", "Q", "<nop>")

-- quick fix list
keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz", { desc = "Quick fix next" })
keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz", { desc = "Quick fix previous" })
keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Location list next" })
keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Location list previous" })

-- clear search highlights
keymap.set("n", "<leader>/c", ":nohl<CR>", { desc = "Clear search highlights" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- tabs
keymap.set("n", "<leader>tt", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tw", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tb", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>ss", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sw", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window
keymap.set("n", "<leader>sh", "<C-w>h", { desc = "Move window left" })
keymap.set("n", "<leader>sj", "<C-w>j", { desc = "Move window down" })
keymap.set("n", "<leader>sk", "<C-w>k", { desc = "Move window up" })
keymap.set("n", "<leader>sl", "<C-w>l", { desc = "Move window right" })
keymap.set("n", "<leader>sH", "<C-w>5<", { desc = "Resize window left" })
keymap.set("n", "<leader>sJ", "<C-w>5-", { desc = "Resize window down" })
keymap.set("n", "<leader>sK", "<C-w>5+", { desc = "Resize window up" })
keymap.set("n", "<leader>sL", "<C-w>5>", { desc = "Resize window right" })

-- additional keymaps
keymap.set(
	"n",
	"<leader>rs",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Replace word on cursor" }
)

keymap.set("n", "<leader><leader>", function()
	cmd("so")
end, { desc = "Source file" })
