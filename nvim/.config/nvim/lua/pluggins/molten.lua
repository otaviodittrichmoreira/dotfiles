-- Select the current "Molten paragraph" / cell between # %%
function SelectCell()
	local bufnr = vim.api.nvim_get_current_buf()
	local curline = vim.api.nvim_win_get_cursor(0)[1] -- current line (1-indexed)
	local lastline = vim.api.nvim_buf_line_count(bufnr)

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, lastline, false)

	-- Find start of cell
	local start_line = 1
	for i = curline, 1, -1 do
		if lines[i]:match("^%s*# %%") then
			start_line = i
			break
		end
	end

	-- Find end of cell
	local end_line = lastline
	for i = curline + 1, lastline do
		if lines[i]:match("^%s*# %%") then
			end_line = i - 1
			break
		end
	end

	-- Select the range in visual line mode
	vim.api.nvim_win_set_cursor(0, { start_line, 0 })
	vim.cmd("normal! V")
	vim.api.nvim_win_set_cursor(0, { end_line, 0 })
end

return {
	"benlubas/molten-nvim",
	version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
	dependencies = { "3rd/image.nvim" },
	build = ":UpdateRemotePlugins",
	init = function()
		-- these are examples, not defaults. Please see the readme
		vim.g.molten_image_provider = "image.nvim"
		vim.g.molten_output_win_max_height = 20
	end,
	config = function()
		vim.keymap.set("n", ",mi", ":MoltenInit<CR>", { silent = true, desc = "Initialize the plugin" })
		vim.keymap.set("n", ",e", ":MoltenEvaluateOperator<CR>", { silent = true, desc = "run operator selection" })
		vim.keymap.set("n", ",rl", ":MoltenEvaluateLine<CR>", { silent = true, desc = "evaluate line" })
		vim.keymap.set("n", ",rr", ":MoltenReevaluateCell<CR>", { silent = true, desc = "re-evaluate cell" })
		-- Insert "# %%"
		vim.keymap.set("n", ",c", function()
			vim.api.nvim_put({ "# %%" }, "l", true, true)
		end, { silent = true, desc = "Insert code cell delimiter" })

		-- Insert "# %% [markdown]"
		vim.keymap.set("n", ",m", function()
			vim.api.nvim_put({ "# %% [markdown]" }, "l", true, true)
		end, { silent = true, desc = "Insert markdown cell delimiter" })
		vim.keymap.set("n", ",rc", function()
			-- Call your existing SelectCell function to select the cell
			SelectCell()

			-- -- Evaluate the visual selection with Molten
			vim.cmd("MoltenEvaluateVisual")

			-- -- Exit visual mode
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
		end, { silent = true, desc = "Run cell delimited by # %%" })
		vim.keymap.set(
			"n",
			",rp",
			"vip::<C-u>MoltenEvaluateVisual<CR>gv<Esc>",
			{ silent = true, desc = "Evaluate paragraph" }
		)
		vim.keymap.set(
			"v",
			",r",
			":<C-u>MoltenEvaluateVisual<CR>gv<Esc>",
			{ silent = true, desc = "evaluate visual selection" }
		)
	end,
}
