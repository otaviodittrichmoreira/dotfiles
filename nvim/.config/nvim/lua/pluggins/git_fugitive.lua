return {
	"tpope/vim-fugitive",
	config = function()
		vim.keymap.set("n", "<leader>gs", ":Git<CR>", { silent = true, desc = "Git status" })
		vim.keymap.set("n", "<leader>gd", ":Git diff<CR>", { silent = true, desc = "Git diff" })
		vim.keymap.set("n", "<leader>gD", ":Gvdiffsplit!<CR>", { silent = true, desc = "Git diff 3-way" })
		vim.keymap.set("n", "<leader>gC", "<C-w>h<C-w>q<C-w>l<C-w>q", { silent = true, desc = "Close 3-way diff" })
		vim.keymap.set("n", "<leader>dr", ":diffget //2<CR>", { silent = true, desc = "Diff get left" })
		vim.keymap.set("n", "<leader>dl", ":diffget //3<CR>", { silent = true, desc = "Diff get right" })
		vim.keymap.set("n", "<leader>ga", ":Git add %<CR>", { silent = true, desc = "Git add" })
	end,
}
