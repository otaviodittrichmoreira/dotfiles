-- Save messages in a new buffer
vim.keymap.set(
	"n",
	"<leader>m",
	":new<CR>:put =execute('message')<CR>",
	{ silent = true, desc = "Paste messages in a new buffer" }
)

-- Toggle NvimTree
vim.keymap.set("n", "<Leader>ee", ":NvimTreeToggle<CR>", { silent = true })

-- Save file
vim.keymap.set("n", "<Leader>j", ":w<CR>", { silent = true, desc = "Save" })

-- Copilot accept word
vim.keymap.set("i", "<C-l>", "<Plug>(copilot-accept-word)")

-- Refresh UltiSnips snippets
vim.keymap.set("n", "<Leader>ur", function()
	vim.cmd("call UltiSnips#RefreshSnippets()")
	vim.notify("UltiSnips snippets reloaded", vim.log.levels.INFO)
end, {
	silent = true,
	desc = "Update Snippet",
})

-- Run python file in a tmux pane
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			"<Leader>r",
			[[:up<CR>:execute "silent !tmux send-keys -t top-right -X cancel; tmux send-keys -t top-right C-u 'python3 %:p' C-m" <CR>]],
			{ noremap = true, silent = true, desc = "Run python file in a tmux pane" }
		)
	end,
})

-- Window key
vim.keymap.set("n", "<Leader>w", "<C-w>")

-- Yank diagnostics with corresponding lines
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

-- Yank diagnostics with corresponding lines in normal mode
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

-- Print defined variable
local esc = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)
vim.fn.setreg("p", [[^"vyinviv]] .. esc .. [[oprint(f"{ = }")]] .. esc .. [[6h"vp]])

vim.keymap.set("n", "<Leader>p", "@p", { desc = "Print defined variable" })

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.api.nvim_buf_set_keymap(
			0,
			"n",
			"<Leader>a",
			[[:up<CR>:lua require("tmux_runner").run_in_tmux()<CR>]],
			{ noremap = true, silent = true, desc = "Run file in a tmux pane" }
		)
	end,
})

vim.keymap.set("n", "<s-z>", ":ZenMode<CR>", { noremap = true, silent = true, desc = "Run python file in a tmux pane" })

local function ensure_repl_open()
	local dapui = require("dapui")
	-- Open REPL if not open
	dapui.open({ reset = false })
end

local function dedent_lines(lines)
	local min_indent = nil
	for _, line in ipairs(lines) do
		if line:match("%S") then -- non-empty line
			local indent = line:match("^(%s*)")
			if min_indent == nil or #indent < #min_indent then
				min_indent = indent
			end
		end
	end

	if not min_indent then
		return lines -- all lines empty, nothing to dedent
	end

	local dedented = {}
	for _, line in ipairs(lines) do
		if line:match("%S") then
			-- Remove only the min_indent prefix
			local pattern = "^" .. vim.pesc(min_indent)
			local dedented_line = line:gsub(pattern, "", 1)
			table.insert(dedented, dedented_line)
		else
			table.insert(dedented, "") -- keep blank lines empty
		end
	end

	return dedented
end

local function scroll_repl_to_bottom()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local ft = vim.api.nvim_buf_get_option(buf, "filetype")
		if ft == "dap-repl" and vim.api.nvim_win_is_valid(win) then
			local line_count = vim.api.nvim_buf_line_count(buf)
			vim.api.nvim_win_call(win, function()
				vim.api.nvim_win_set_cursor(win, { line_count, 0 })
				vim.cmd("normal! zb") -- scroll to put cursor at bottom of window
			end)
			break
		end
	end
end

vim.keymap.set("v", "<Leader>dr", function()
	ensure_repl_open()

	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local lines = vim.fn.getline(start_pos[2], end_pos[2])

	if #lines > 0 then
		lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
		lines[1] = string.sub(lines[1], start_pos[3])
	end

	lines = dedent_lines(lines)

	require("dap.repl").execute(table.concat(lines, "\n"))
	vim.cmd("redraw")
	scroll_repl_to_bottom()
end, { silent = true, desc = "[D]ebug: Send selection to [R]EPL" })

vim.keymap.set("n", "<Leader>dr", function()
	ensure_repl_open()

	local line = vim.api.nvim_get_current_line()
	-- Dedent the line before sending, wrap line in a table since dedent_lines expects a list
	local dedented_lines = dedent_lines({ line })
	require("dap.repl").execute(dedented_lines[1])

	vim.cmd("redraw")
	scroll_repl_to_bottom()
end, { silent = true, desc = "[D]ebug: Send line to [R]EPL" })
