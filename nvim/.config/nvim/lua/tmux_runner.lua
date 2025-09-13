local M = {}

function M.run_in_tmux(reset_command)
	local buf_cmd = vim.b.tmux_run_cmd
	local default = "python3 %:p"
	if reset_command then
		default = buf_cmd
		buf_cmd = ""
	end

	if not buf_cmd or buf_cmd == "" then
		vim.ui.input({ prompt = "Enter command: ", default = default }, function(input)
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
	local current_pane = vim.fn.system("tmux display-message -p '#{pane_id}'"):gsub("\n", "")
	-- Find the pane physically at the top-right
	local target_pane = vim.fn
		.system([[
		tmux list-panes -F "#{pane_id} #{pane_left} #{pane_top} #{pane_right}" \
		| awk 'NR==1 || ($4>max_right) || ($4==max_right && $3<min_top) {id=$1; max_right=$4; min_top=$3} END{print id}'
	]])
		:gsub("\n", "")

	if current_pane ~= target_pane then
		local vim_cmd = string.format(
			[[execute "silent !tmux send-keys -t top-right -X cancel; tmux send-keys -t top-right C-u '%s' C-m"]],
			escaped_cmd
		)
		vim.cmd("up") -- save buffer
		vim.cmd(vim_cmd)
	else
		-- print("Target pane not found.")
		vim.cmd("up") -- save buffer
		vim.cmd(":make")
	end
end

return M
