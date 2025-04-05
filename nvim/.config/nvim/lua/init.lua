require("motion")
require("kickstart")
require("settings")
require("pluggins.ultisnips")
-- require("pluggins.rainbow_setting")
-- require 'pluggins.rainbow_delimiter'
-- require 'cmp_setup'
require("mini.align").setup()
require("mini.surround").setup()
require("mini.jump").setup()
require("mini.move").setup()
require("mini.operators").setup()
require("mini.splitjoin").setup()
-- require("mini.jump2d").setup()
require("mini.icons").setup()
require("mini.starter").setup()
-- require("mini.git").setup()

-- vim.opt.relativenumber = true

vim.api.nvim_create_autocmd("FileType", {
	pattern = "tex",
	callback = function()
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.expandtab = true
	end,
})

-- local rhs = "<Cmd>lua MiniGit.show_at_cursor()<CR>"
-- vim.keymap.set({ "n", "x" }, "<Leader>gs", rhs, { desc = "Show at cursor" })
vim.keymap.set("n", "<Leader>ee", ":NvimTreeToggle<CR>", { silent = true })
vim.keymap.set("n", "<Leader>j", ":w<CR>", { silent = true, desc = "Save" })
vim.keymap.set("n", "<C-w>f", ":NvimTreeFindFile<CR>", { silent = true })
vim.keymap.set("i", "<M-l>", "<Plug>(copilot-accept-word)")
vim.keymap.set("n", "<Leader>ur", ":call UltiSnips#RefreshSnippets()<CR>", { silent = true, desc = "Update Snippet" })
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			"<Leader>r",
			[[:up<CR>:execute "silent !tmux send-keys -t top-right 'python3 %' C-m" <CR>]],
			{ noremap = true, silent = true, desc = "Run python file in a tmux pane" }
		)
	end,
})
vim.keymap.set("n", "<Leader>w", "<C-w>")

vim.keymap.set("v", "<leader>yd", function()
	vim.fn.setreg("+", "")
	local start_line = vim.fn.line("v") - 1 -- Get visual selection start (0-based)
	local end_line = vim.fn.line(".") - 1 -- Get visual selection end (0-based)

	if start_line > end_line then
		start_line, end_line = end_line, start_line -- Ensure correct order
	end

	local messages = {}
	for lnum = start_line, end_line do
		local line_text = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1] or "" -- Get the actual line content
		local diags = vim.diagnostic.get(0, { lnum = lnum })

		if #diags > 0 then
			table.insert(messages, string.format("%d: %s", lnum + 1, line_text)) -- Add line number & content
			for _, d in ipairs(diags) do
				table.insert(messages, string.format("    ↳ %s", d.message)) -- Indent diagnostic message
			end
		end
	end

	if #messages > 0 then
		vim.fn.setreg("+", table.concat(messages, "\n")) -- Yank to system clipboard
		print("Diagnostics and corresponding lines yanked!")
	else
		print("No diagnostics in selection.")
	end
end, { desc = "Yank diagnostics with corresponding lines" })

vim.keymap.set("n", "<leader>yd", function()
	local lnum = vim.fn.line(".") - 1 -- Get the current line number (0-based)
	local line_text = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1] or ""
	local diags = vim.diagnostic.get(0, { lnum = lnum })

	-- Clear the D register before saving new content
	vim.fn.setreg("+", "")

	if #diags > 0 then
		local messages = { string.format("%d: %s", lnum + 1, line_text) } -- Add line number & content
		for _, d in ipairs(diags) do
			table.insert(messages, string.format("    ↳ %s", d.message)) -- Indent diagnostic message
		end
		vim.fn.setreg("+", table.concat(messages, "\n")) -- Save to register 'd'
		print("Diagnostics and line saved to register +!")
	else
		print("No diagnostics on this line.")
	end
end, { desc = "Save current line's diagnostics to register +" })
