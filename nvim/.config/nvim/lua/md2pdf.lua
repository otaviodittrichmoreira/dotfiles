-- Run md2pdf every time a Markdown file is saved
vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "*.md",
	callback = function()
		local file = vim.fn.expand("%:p")
		vim.fn.jobstart({ "md2pdf", file }, { detach = true })
	end,
})
