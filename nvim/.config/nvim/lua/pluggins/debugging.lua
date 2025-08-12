return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"mfussenegger/nvim-dap-python",
		"nvim-neotest/nvim-nio",
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
		vim.keymap.set("n", "<Leader>dl", function()
			toggle_float("scopes", { width = 100, height = 20 }, "Scopes")
		end, { silent = true, desc = "Toggle [S]copes floating window" })

		vim.keymap.set("n", "<Leader>dw", function()
			toggle_float("watches", { width = 100, height = 20 }, "Watches")
		end, { silent = true, desc = "Toggle [W]atches floating window" })

		-- Symbols
		vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "ErrorMsg" })
		vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "WarningMsg" })
		vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "MoreMsg" })
		vim.fn.sign_define("DapStopped", { text = "▶", texthl = "Title", linehl = "CursorLine" })

		-- Debugging keymaps
		vim.keymap.set("n", "<Leader>db", dap.toggle_breakpoint, { silent = true, desc = "Set a [B]reakpoint" })
		vim.keymap.set("n", "<Leader>dc", dap.continue, { silent = true, desc = "[C]ontinue (or start) debugging" })
	end,
}
