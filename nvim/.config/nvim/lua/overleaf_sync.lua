-- Quietly synchronize Overleaf Git repositories after saving a file.
--
-- The origin URL must be https://git.overleaf.com/<project-id>. Fetches are
-- asynchronous, non-interactive, and silent on every failure (including when
-- offline). When origin has commits that HEAD does not contain, a floating
-- prompt offers a fast-forward-only pull. Saved but uncommitted changes are
-- automatically stashed and reapplied around that pull. Once the remote is
-- current, all repository changes are staged, committed as "Update" (when
-- needed), and pushed. Choosing No (or Esc) disables both pulling and pushing
-- for every repository until Neovim is restarted.
local M = {}
local api = vim.api

local disabled = false
local repos = {}
local group_name = "overleaf_sync"

local function trim(value)
	local trimmed = (value or ""):gsub("%s+$", "")
	return trimmed
end

local function is_overleaf_url(url)
	return trim(url):match("^https://git%.overleaf%.com/[^/%s?#]+/?$") ~= nil
end

local function run_git(root, args, timeout, callback)
	local command = { "git", "-C", root }
	vim.list_extend(command, args)

	local ok, job = pcall(vim.system, command, {
		text = true,
		timeout = timeout,
		env = {
			GIT_TERMINAL_PROMPT = "0",
			GIT_ASKPASS = "true",
			SSH_ASKPASS = "true",
			GCM_INTERACTIVE = "never",
		},
	}, vim.schedule_wrap(callback))

	if not ok then
		vim.schedule(function()
			callback({ code = -1, stdout = "", stderr = "" })
		end)
	end
	return ok and job or nil
end

local function stop(repo)
	repo.running = false
	repo.job = nil
	if disabled then
		return
	end
	if repo.pending then
		repo.pending = false
		vim.schedule(function()
			M.check(repo.root)
		end)
	end
end

local function disable_for_session()
	disabled = true
	for _, repo in pairs(repos) do
		repo.pending = false
		if repo.job and not repo.job:is_closing() then
			pcall(repo.job.kill, repo.job, 15)
		end
	end
end

local function publish(repo)
	if disabled then
		stop(repo)
		return
	end
	local branch = repo.remote_ref and repo.remote_ref:match("^origin/(.+)$")
	if not branch then
		stop(repo)
		return
	end

	local function push()
		repo.job = run_git(repo.root, { "push", "--quiet", "origin", "HEAD:refs/heads/" .. branch }, 60000, function()
			stop(repo)
		end)
	end

	repo.running = true
	repo.job = run_git(repo.root, { "add", "--all" }, 10000, function(add_result)
		if add_result.code ~= 0 or disabled then
			stop(repo)
			return
		end
		repo.job = run_git(repo.root, { "diff", "--cached", "--quiet" }, 5000, function(diff_result)
			if diff_result.code == 0 then
				-- Nothing new to commit, but publish any commits already ahead of origin.
				push()
			elseif diff_result.code == 1 then
				repo.job = run_git(repo.root, { "commit", "--quiet", "--message", "Update" }, 60000, function(commit_result)
					if commit_result.code == 0 and not disabled then
						push()
					else
						stop(repo)
					end
				end)
			else
				stop(repo)
			end
		end)
	end)
end

local function update_prompt(repo, count)
	if disabled or repo.prompt_open then
		return
	end
	repo.prompt_open = true

	local lines = {
		("Overleaf has %d remote update%s."):format(count, count == 1 and "" or "s"),
		"Pull, then commit and push local changes?",
		"[y/Enter] Sync    [n/Esc] No; stop syncing this session",
	}
	local width = math.max(30, math.min(68, vim.o.columns - 4))
	local buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	local win = api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = "rounded",
		title = " Overleaf update available ",
		title_pos = "center",
		width = width,
		height = #lines,
		row = math.max(0, math.floor((vim.o.lines - #lines - 2) / 2)),
		col = math.max(0, math.floor((vim.o.columns - width) / 2)),
	})
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].modifiable = false

	local answered = false
	local function close()
		if answered then
			return false
		end
		answered = true
		repo.prompt_open = false
		if api.nvim_win_is_valid(win) then
			api.nvim_win_close(win, true)
		end
		return true
	end

	local function decline()
		if close() then
			disable_for_session()
		end
	end

	local function pull()
		if not close() or disabled then
			return
		end
		repo.running = true
		local branch = repo.remote_ref and repo.remote_ref:match("^origin/(.+)$")
		if not branch then
			stop(repo)
			return
		end
		repo.job = run_git(
			repo.root,
			{ "pull", "--quiet", "--ff-only", "--autostash", "origin", branch },
			60000,
			function(result)
				repo.job = nil
				if result.code == 0 and not disabled then
					-- Reload unchanged buffers and warn normally for locally modified ones.
					pcall(vim.cmd, "checktime")
					publish(repo)
				else
					stop(repo)
				end
			end
		)
	end

	for _, key in ipairs({ "y", "Y", "<CR>" }) do
		vim.keymap.set("n", key, pull, { buffer = buf, nowait = true })
	end
	for _, key in ipairs({ "n", "N", "<Esc>", "<C-c>" }) do
		vim.keymap.set("n", key, decline, { buffer = buf, nowait = true })
	end
end

local function compare_remote(repo)
	local function compare(ref)
		repo.remote_ref = ref
		repo.job = run_git(repo.root, { "rev-list", "--count", "HEAD.." .. ref }, 5000, function(result)
			if result.code ~= 0 then
				stop(repo)
				return
			end
			local count = tonumber(trim(result.stdout)) or 0
			if count > 0 then
				update_prompt(repo, count)
				stop(repo)
			else
				publish(repo)
			end
		end)
	end

	-- Prefer the configured origin upstream, then origin/<current-branch>.
	repo.job = run_git(
		repo.root,
		{ "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}" },
		5000,
		function(result)
			local upstream = result.code == 0 and trim(result.stdout) or ""
			if upstream:match("^origin/.+") then
				compare(upstream)
				return
			end
			repo.job = run_git(repo.root, { "symbolic-ref", "--quiet", "--short", "HEAD" }, 5000, function(branch_result)
				if branch_result.code ~= 0 then
					stop(repo)
					return
				end
				local branch = trim(branch_result.stdout)
				if branch == "" then
					stop(repo)
					return
				end
				compare("origin/" .. branch)
			end)
		end
	)
end

local function fetch(repo)
	repo.running = true
	repo.job = run_git(repo.root, { "fetch", "--quiet", "--no-tags", "origin" }, 20000, function(result)
		if disabled then
			stop(repo)
		elseif result.code == 0 then
			compare_remote(repo)
		else
			-- Offline, authentication, timeout, and other fetch failures are silent.
			stop(repo)
		end
	end)
end

function M.check(root)
	if disabled or not root then
		return
	end
	local repo = repos[root]
	if not repo then
		repo = { root = root }
		repos[root] = repo
	end
	if repo.running or repo.prompt_open then
		repo.pending = true
		return
	end
	if repo.overleaf == false then
		return
	end
	if repo.overleaf then
		fetch(repo)
		return
	end

	repo.running = true
	repo.job = run_git(root, { "config", "--get", "remote.origin.url" }, 5000, function(result)
		repo.overleaf = result.code == 0 and is_overleaf_url(result.stdout)
		if repo.overleaf then
			fetch(repo)
		else
			stop(repo)
		end
	end)
end

function M.setup()
	local group = api.nvim_create_augroup(group_name, { clear = true })
	api.nvim_create_autocmd("BufWritePost", {
		group = group,
		desc = "Silently synchronize an Overleaf Git repository",
		callback = function(event)
			if disabled then
				return
			end
			local path = api.nvim_buf_get_name(event.buf)
			if path == "" then
				return
			end
			M.check(vim.fs.root(path, ".git"))
		end,
	})
end

return M
