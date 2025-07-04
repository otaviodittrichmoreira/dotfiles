local M = {}

function M.run_in_tmux()
	local buf_cmd = vim.b.tmux_run_cmd

	if not buf_cmd or buf_cmd == "" then
		vim.ui.input({ prompt = "Enter command to run in tmux: ", default = "" }, function(input)
			if input and input ~= "" then
				vim.b.tmux_run_cmd = input
				M._send_tmux_exec(input)
			else
				vim.notify("No command provided, aborting.", vim.log.levels.WARN)
			end
		end)
	else
		M._send_tmux_exec(buf_cmd)
	end
end

function M._send_tmux_exec(cmd)
	local escaped_cmd = cmd:gsub("'", [["'"']]) -- escape single quotes safely for shell
	local vim_cmd = string.format([[execute "silent !tmux send-keys -t top-right '%s' C-m"]], escaped_cmd)
	vim.cmd("up") -- save buffer
	vim.cmd(vim_cmd)
end

return M
