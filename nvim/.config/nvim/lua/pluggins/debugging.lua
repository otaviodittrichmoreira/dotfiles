return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"mfussenegger/nvim-dap-python",
		"nvim-neotest/nvim-nio",
	},
	config = function()
		require("dap-python").setup("python3")
		require("dapui").setup()

		local dap = require("dap")
		local dapui = require("dapui")
		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end

		vim.keymap.set("n", "<Leader>db", dap.toggle_breakpoint, {})
		vim.keymap.set("n", "<Leader>dc", dap.continue, {})
		vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "ErrorMsg", linehl = "", numhl = "" })
		vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "WarningMsg", linehl = "", numhl = "" })
		vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "MoreMsg", linehl = "", numhl = "" })
		vim.fn.sign_define("DapStopped", { text = "▶", texthl = "Title", linehl = "CursorLine", numhl = "" })
	end,
}
