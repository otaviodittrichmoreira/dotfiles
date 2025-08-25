return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"mfussenegger/nvim-dap-python",
		"nvim-neotest/nvim-nio",
		"rcarriga/cmp-dap",
	},
	config = function()
		require("dap-python").setup("python3")

		local dapui = require("dapui")

		dapui.setup({
			layouts = {
				-- Right split: top = console, bottom = REPL
				{
					elements = {
						{ id = "console", size = 0.5 },
						{ id = "repl", size = 0.5 },
					},
					position = "right",
					size = 50,
				},
			},
		})

		local dap = require("dap")

		local function open_debug_ui()
			dapui.open()
		end

		local function close_debug_ui()
			dapui.close()
		end

		dap.listeners.before.attach.dapui_config = open_debug_ui
		dap.listeners.before.launch.dapui_config = open_debug_ui
		dap.listeners.before.event_terminated.dapui_config = close_debug_ui
		dap.listeners.before.event_exited.dapui_config = close_debug_ui

		-- Track floating window handles so we can close them
		local float_windows = {
			scopes = nil,
			watches = nil,
		}

		local function toggle_float(name, size, title)
			-- If already open, close it
			if float_windows[name] and vim.api.nvim_win_is_valid(float_windows[name]) then
				vim.api.nvim_win_close(float_windows[name], true)
				float_windows[name] = nil
			else
				-- Open new floating element
				float_windows[name] = dapui.float_element(name, {
					width = size.width,
					height = size.height,
					position = "center",
					enter = false,
					title = title,
				})
			end
		end

		-- Keymaps for toggling floats
		vim.keymap.set("n", "<Leader>dv", function()
			toggle_float("scopes", { width = 60, height = 20 }, "Scopes")
		end, { silent = true, desc = "Toggle [S]copes floating window" })

		vim.keymap.set("n", "<Leader>dw", function()
			toggle_float("watches", { width = 60, height = 10 }, "Watches")
		end, { silent = true, desc = "Toggle [W]atches floating window" })

		-- Symbols
		vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "ErrorMsg" })
		vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "WarningMsg" })
		vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "MoreMsg" })
		vim.fn.sign_define("DapStopped", { text = "▶", texthl = "Title", linehl = "CursorLine" })

		-- Debugging keymaps
		local first_run_done = false

		vim.keymap.set("n", "<Leader>db", dap.toggle_breakpoint, { silent = true, desc = "Set a [B]reakpoint" })
		vim.keymap.set("n", "<Leader>dc", function()
			-- Zoom the pane if not already
			vim.fn.system("tmux if -F '#{window_zoomed_flag}' '' 'resize-pane -Z'")
			vim.cmd("write")
			first_run_done = true
			dap.continue()
		end, { silent = true, desc = "[C]ontinue (or start) debugging" })
		vim.keymap.set("n", "<Leader>dr", function()
			vim.fn.system("tmux if -F '#{window_zoomed_flag}' '' 'resize-pane -Z'")
			vim.cmd("write")
			dap.restart()
		end, { silent = true, desc = "[R]estart debugging" })
		vim.keymap.set("n", "<Leader>dt", dap.terminate, { silent = true, desc = "[T]erminate debugging" })
		vim.keymap.set("n", "<Leader>do", dap.step_over, { silent = true, desc = "[D]ebugging Step [O]ver" })
		vim.keymap.set("n", "<Leader>di", dap.step_into, { silent = true, desc = "[D]ebugging Step [I]nto" })
		vim.keymap.set({ "n", "v" }, "<Leader>dh", function()
			require("dap.ui.widgets").hover()
		end, { silent = true, desc = "[H]over" })

		vim.keymap.set("n", "<Leader>dl", function()
			vim.fn.system("tmux if -F '#{window_zoomed_flag}' '' 'resize-pane -Z'")
			vim.cmd("write")
			if not first_run_done then
				dap.continue()
				first_run_done = true
			else
				dap.run_last()
			end
		end, { silent = true, desc = "[D]ebug: Run [L]ast or start new" })

		-- vim.keymap.set("n", "<Leader>dg", dap.run_to_cursor, { silent = true, desc = "[D]ebugging [G]o to cursor" })

		vim.keymap.set("n", "<Leader>dg", function()
			vim.fn.system("tmux if -F '#{window_zoomed_flag}' '' 'resize-pane -Z'")
			vim.cmd("write")
			if dap.session() == nil then
				-- no active session, so start debugging first
				dap.clear_breakpoints()
				dap.toggle_breakpoint()
				if first_run_done then
					dap.run_last()
				else
					dap.continue()
				end
			else
				-- session active, just run to cursor
				dap.run_to_cursor()
			end
			first_run_done = true
		end, { silent = true, desc = "[D]ebugging [G]o to cursor (start if needed)" })

		-- Esc closes dap float
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "dap-float",
			callback = function()
				vim.keymap.set("n", "<Esc>", "<Cmd>close!<CR>", { buffer = true, silent = true })
			end,
		})

		-- Completion
		local cmp = require("cmp")
		cmp.setup({
			-- other settings and stuff
			enabled = function()
				return vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt" or require("cmp_dap").is_dap_buffer()
			end,
		})

		cmp.setup.filetype({ "dap-repl", "dapui_watches" }, {
			sources = {
				{ name = "dap" },
			},
		})
	end,
}
