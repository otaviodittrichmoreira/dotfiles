function YankDiagnosticVisualMode()
	vim.fn.setreg("d", "")
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
		vim.fn.setreg("d", table.concat(messages, "\n")) -- Yank to system clipboard
		print("Diagnostics and corresponding lines yanked!")
	else
		print("No diagnostics in selection.")
	end
end

function YankDiagnosticNormalMode()
	local lnum = vim.fn.line(".") - 1 -- Get the current line number (0-based)
	local line_text = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1] or ""
	local diags = vim.diagnostic.get(0, { lnum = lnum })

	-- Clear the D register before saving new content
	vim.fn.setreg("d", "")

	if #diags > 0 then
		local messages = { string.format("%d: %s", lnum + 1, line_text) } -- Add line number & content
		for _, d in ipairs(diags) do
			table.insert(messages, string.format("    ↳ %s", d.message)) -- Indent diagnostic message
		end
		vim.fn.setreg("d", table.concat(messages, "\n")) -- Save to register 'd'
		print("Diagnostics and line saved to register d!")
	else
		print("No diagnostics on this line.")
	end
end

return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "github/copilot.vim", lazy = false }, -- or zbirenbaum/copilot.lua
			{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
		},
		build = "make tiktoken", -- Only on MacOS or Linux
		opts = {
			prompts = {
				Rename = {
					prompt = "Rename all variables in the selection to be more descriptive and follow the snake_case. Ensure names are clear, meaningful, and contextually relevant. For example, rename x to time_steps if it represents time steps in a sequence. Maintain consistency across similar variables",
					selection = function(source)
						local select = require("CopilotChat.select")
						return select.visual(source)
					end,
					system_prompt = "COPILOT_RENAME",
				},
				Docs = {
					prompt = "Generate NumPy-style docstrings for all functions and classes in this script. Ensure each function includes a concise description, parameters (name: type format), return values, and a brief example. Maintain consistency and readability",
					system_prompt = "COPILOT_DOCS",
				},
				Explain = {
					prompt = "Explain the selected code code in detail. Break down its logic, purpose, and key functions. Ensure clarity and readability for someone unfamiliar with the code.",
					selection = function(source)
						local select = require("CopilotChat.select")
						return select.visual(source)
					end,
					system_prompt = "COPILOT_EXPLAIN",
				},
				Review = {
					prompt = "Review the following code for best practices, readability, and performance. Identify potential bugs, inefficiencies, and areas for improvement. Suggest refactorings, optimizations, and security enhancements where necessary. Provide clear and actionable feedback.",
					selection = function(source)
						local select = require("CopilotChat.select")
						return select.visual(source)
					end,
					system_prompt = "COPILOT_REVIEW",
				},
				Fix = {
					prompt = "Explain the error and provide one simple fix to the issue while maintaining its intended functionality.",
					selection = function(source)
						local select = require("CopilotChat.select")
						return select.visual(source)
					end,
					system_prompt = "COPILOT_FIX",
					context = { "register:d", "#buffer" },
				},
			},
		},
		-- See Commands section for default commands if you want to lazy load on them
		keys = {
			{ "<leader>zc", ":CopilotChatToggle<CR>", mode = "n", desc = "Toggle Copilot Chat", silent = true },
			{ "<leader>ze", ":CopilotChatExplain<CR>", mode = "v", desc = "Explain Selected Code", silent = true },
			{ "<leader>zr", ":CopilotChatReview<CR>", mode = "v", desc = "Review Selected Code", silent = true },
			{
				"<leader>zf",
				function()
					YankDiagnosticVisualMode()
					vim.cmd("CopilotChatFix")
				end,
				mode = "v",
				desc = "Fix Selected Code",
				silent = true,
			},
			{
				"<leader>zf",
				function()
					-- Go to visual mode
					vim.cmd("normal! v")
					YankDiagnosticVisualMode()
					vim.cmd("CopilotChatFix")
				end,
				mode = "n",
				desc = "Fix Selected Code",
				silent = true,
			},
			{ "<leader>zo", ":CopilotChatOptmize<CR>", mode = "v", desc = "Optimize Code", silent = true },
			{ "<leader>zd", ":CopilotChatDocs<CR>", mode = "v", desc = "Generate Docs", silent = true },
			{ "<leader>zt", ":CopilotChatTests<CR>", mode = "v", desc = "Generate Tests", silent = true },
			{ "<leader>zm", ":CopilotChatCommit<CR>", mode = "n", desc = "Generate Commit Message", silent = true },
			{ "<leader>zn", ":CopilotChatRename<CR>", mode = "v", desc = "Rename the variable", silent = true },
			{
				"<leader>zs",
				":CopilotChatCommit<CR>",
				mode = "v",
				desc = "Generate Commit Message for Selection",
				silent = true,
			},
		},
	},
}
