-- File-manager clipboard import (Linux, Neovim >= 0.10).
-- Loaded by require('file_paste').setup(); no plugin dependency.
--
-- Usage: copy a FILE in a file manager or VS Code Explorer, then p/P, "+p, <C-r>+, or use
-- terminal bracketed paste. :PasteFile explicitly imports the clipboard file.
-- Floating dialogs: y/Enter confirms, n/Esc cancels; filename Enter accepts.
-- Blank filename keeps the source basename (plot.png, plot_1.png, plot_2.png
-- on collisions). Images without a source path use pasted_image_YYYYMMDD<index>.png
-- (or the clipboard image's original extension).
-- "Upload" means a local copy, never a network upload. Sources are never moved,
-- even if the file manager used Cut. One regular local file per paste is supported.
-- Needs xclip (X11) or wl-paste (Wayland); reads file MIME types, not arbitrary
-- text paths. Includes VS Code's code/file-list (newline-separated file URIs).
-- Notebook/browser Copy Image is supported through binary image/png, image/jpeg,
-- and image/webp clipboard data. Use p/P, <C-r>+, or :PasteFile for images:
-- terminals may not send a paste event when the clipboard has no text.
-- Terminal paste must match the clipboard URI/path to intercept it.
-- Named registers and ordinary text retain native paste behavior.
--
-- TeX root: b:vimtex.root, % !TeX root directive, nearest main.tex/.git,
-- then buffer directory. rg searches .tex/.sty for literal \graphicspath,
-- including ignored files. Relative graphics paths are rooted at the TeX root,
-- NOT at the file containing the declaration. First literal path wins; main
-- file is preferred. This is not a TeX interpreter: macros/conditional path
-- declarations need a literal path or manual placement. Unsaved preamble edits
-- should be saved first. PNG/JPEG/PDF/EPS/SVG/etc. get a figure environment;
-- .tex gets \input; other types are copied without inserting unsupported TeX.
-- SVG and other nonstandard graphics formats still need suitable LaTeX packages.
-- Replacement preserves the old name and requires matching extensions (no image
-- conversion). Archives go in the old figure's .graveyard/name_<index>.ext.
-- Filesystem changes are not undone by Neovim's text undo. Existing destinations
-- are never overwritten by a normal import. Replacement stages the new file and
-- keeps an exclusive archive before changing the original.
local M = {}
local uv = vim.uv or vim.loop
local api = vim.api
local busy = false
local graphics = {
	png = true,
	jpg = true,
	jpeg = true,
	pdf = true,
	eps = true,
	svg = true,
	webp = true,
	gif = true,
	bmp = true,
	tif = true,
	tiff = true,
}
local function warn(msg)
	vim.notify("File paste: " .. msg, vim.log.levels.WARN)
end
local function join(a, b)
	return vim.fs.normalize(b:sub(1, 1) == "/" and b or (a .. "/" .. b))
end
local function exists(p)
	return uv.fs_lstat(p) ~= nil
end
local function extension(p)
	return p:match("%.([^./]+)$") or ""
end
local function run(args, binary)
	local ok, result = pcall(function()
		return vim.system(args, { text = not binary }):wait(binary and 5000 or 1000)
	end)
	if ok and result.code == 0 then
		return result.stdout
	end
end

-- Only file-transfer or image MIME types qualify. In particular, stale files in the
-- clipboard cannot turn a normal text/register paste into an import.
local function clipboard()
	local backends = {}
	if vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-paste") == 1 then
		backends[#backends + 1] =
			{ list = { "wl-paste", "--list-types" }, read = { "wl-paste", "--no-newline", "--type" } }
	end
	if vim.env.DISPLAY and vim.fn.executable("xclip") == 1 then
		backends[#backends + 1] = {
			list = { "xclip", "-selection", "clipboard", "-o", "-t", "TARGETS" },
			read = { "xclip", "-selection", "clipboard", "-o", "-t" },
		}
	end
	for _, backend in ipairs(backends) do
		local types = run(backend.list) or ""
		local offered = {}
		for mime in types:gmatch("[^\r\n]+") do
			offered[mime] = true
		end
		for _, mime in ipairs({ "x-special/gnome-copied-files", "text/uri-list", "code/file-list" }) do
			if offered[mime] then
				local args = vim.deepcopy(backend.read)
				args[#args + 1] = mime
				local raw = run(args)
				if raw then
					local paths, uris = {}, {}
					for line in raw:gmatch("[^\r\n]+") do
						if line ~= "copy" and line ~= "cut" and line:sub(1, 1) ~= "#" then
							local host, path = line:match("^file://([^/]*)(/.*)$")
							if not path or (host ~= "" and host ~= "localhost") then
								return { error = "Only local file:// clipboard entries are supported." }
							end
							path = path:gsub("%%(%x%x)", function(h)
								return string.char(tonumber(h, 16))
							end)
							if path:find("%z") then
								return { error = "Invalid clipboard filename." }
							end
							paths[#paths + 1], uris[#uris + 1] = path, line
						end
					end
					if #paths ~= 1 then
						return { error = "Copy exactly one file at a time." }
					end
					local stat = uv.fs_stat(paths[1])
					if not stat or stat.type ~= "file" then
						return { error = "Clipboard source is not a readable regular file." }
					end
					return { path = paths[1], uri = uris[1], raw = raw }
				end
			end
		end
		for _, format in ipairs({ { "image/png", "png" }, { "image/jpeg", "jpg" }, { "image/webp", "webp" } }) do
			if offered[format[1]] then
				local args = vim.deepcopy(backend.read)
				args[#args + 1] = format[1]
				-- Never normalize newlines in binary images (PNG includes CRLF).
				local data = run(args, true)
				if data and #data > 0 then
					return { data = data, ext = format[2] }
				end
				return { error = "Could not read clipboard image data; copy the image again." }
			end
		end
	end
end

-- Self-contained floats, independent of whether a UI plugin overrides vim.ui.
local function dialog(title, input, callback)
	vim.cmd("stopinsert")
	local buf = api.nvim_create_buf(false, true)
	local width = math.max(10, math.min(76, vim.o.columns - 4))
	api.nvim_buf_set_lines(buf, 0, -1, false, { input and "" or "[y] Yes    [n] No    [Esc] Cancel" })
	local win = api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = "rounded",
		title = " " .. title:sub(1, width - 4) .. " ",
		title_pos = "center",
		width = width,
		height = 1,
		row = math.max(0, math.floor((vim.o.lines - 4) / 2)),
		col = math.max(0, math.floor((vim.o.columns - width) / 2)),
	})
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].modifiable = input
	local done = false
	local function finish(value)
		if done then
			return
		end
		done = true
		vim.cmd("stopinsert")
		if api.nvim_win_is_valid(win) then
			api.nvim_win_close(win, true)
		end
		vim.schedule(function()
			callback(value)
		end)
	end
	local function accept()
		finish(input and api.nvim_buf_get_lines(buf, 0, 1, false)[1] or true)
	end
	vim.keymap.set({ "n", "i" }, "<CR>", accept, { buffer = buf })
	vim.keymap.set({ "n", "i" }, "<Esc>", function()
		finish(nil)
	end, { buffer = buf })
	vim.keymap.set({ "n", "i" }, "<C-c>", function()
		finish(nil)
	end, { buffer = buf })
	if input then
		vim.cmd("startinsert")
	else
		vim.keymap.set("n", "y", accept, { buffer = buf })
		vim.keymap.set("n", "n", function()
			finish(nil)
		end, { buffer = buf })
	end
	api.nvim_create_autocmd({ "BufLeave", "BufWipeout" }, {
		buffer = buf,
		once = true,
		callback = function()
			if not done then
				vim.schedule(function()
					finish(nil)
				end)
			end
		end,
	})
end

local function uncomment(text)
	local lines = {}
	for line in (text .. "\n"):gmatch("(.-)\n") do
		for i = 1, #line do
			if line:sub(i, i) == "%" then
				local n, j = 0, i - 1
				while j > 0 and line:sub(j, j) == "\\" do
					n = n + 1
					j = j - 1
				end
				if n % 2 == 0 then
					line = line:sub(1, i - 1)
					break
				end
			end
		end
		lines[#lines + 1] = line
	end
	return table.concat(lines, "\n")
end
local function read(path)
	local ok, lines = pcall(vim.fn.readfile, path)
	return ok and table.concat(lines, "\n") or ""
end
local function project(buf, dir)
	local vt = vim.b[buf].vimtex
	if type(vt) == "table" and vt.root then
		return vt.root, vt.tex
	end
	for _, line in ipairs(api.nvim_buf_get_lines(buf, 0, math.min(30, api.nvim_buf_line_count(buf)), false)) do
		local root = line:match("^%s*%%%s*!%s*[Tt][Ee][Xx]%s+root%s*=%s*(.-)%s*$")
		if root then
			local main = join(dir, root)
			return vim.fs.dirname(main), main
		end
	end
	local current = dir
	while current do
		if exists(current .. "/main.tex") then
			return current, current .. "/main.tex"
		end
		if exists(current .. "/.git") then
			return current
		end
		local parent = vim.fs.dirname(current)
		if parent == current then
			break
		end
		current = parent
	end
	return dir
end
local function graphic_dirs(root, main)
	if vim.fn.executable("rg") ~= 1 then
		error("rg is required to find \\graphicspath.")
	end
	local result = vim.system({
		"rg",
		"--files-with-matches",
		"--null",
		"--hidden",
		"--no-ignore",
		"-g",
		"*.tex",
		"-g",
		"*.sty",
		"-g",
		"!.git/**",
		"-g",
		"!.graveyard/**",
		"-F",
		"\\graphicspath",
		root,
	}, { text = true }):wait(5000)
	if result.code ~= 0 and result.code ~= 1 then
		error("rg graphicspath search failed: " .. (result.stderr or ""))
	end
	local files = vim.split(result.stdout or "", "\0", { trimempty = true })
	table.sort(files)
	if main then
		for i, p in ipairs(files) do
			if p == main then
				table.remove(files, i)
				break
			end
		end
		table.insert(files, 1, main)
	end
	for _, file in ipairs(files) do
		local text = uncomment(read(file))
		local body = text:match("\\graphicspath%s*(%b{})")
		if body then
			local dirs = {}
			for item in body:sub(2, -2):gmatch("%b{}") do
				local path = vim.trim(item:sub(2, -2))
				if path:find("[\\#{}]") then
					error("Macro-based graphicspath is unsupported: " .. path)
				end
				dirs[#dirs + 1] = join(root, path)
			end
			if #dirs > 0 then
				return dirs
			end
		end
	end
	return {}
end
local function unique(dir, stem, ext)
	local i = 1
	while exists(dir .. "/" .. stem .. i .. ext) do
		i = i + 1
	end
	return dir .. "/" .. stem .. i .. ext
end
local function relative(path, root)
	local a, b = vim.split(vim.fs.normalize(root), "/"), vim.split(vim.fs.normalize(path), "/")
	while #a > 0 and #b > 0 and a[1] == b[1] do
		table.remove(a, 1)
		table.remove(b, 1)
	end
	for _ = 1, #a do
		table.insert(b, 1, "..")
	end
	return table.concat(b, "/")
end
local function checked(ok, err)
	if not ok then
		error(err or "File operation failed.")
	end
	return ok
end
-- Write bytes only after confirmation. Exclusive creation prevents accidental
-- overwrites, and failed/partial writes are removed. No temporary clipboard
-- files are left behind when a prompt is cancelled.
local function copy_source(clip, dest)
	if clip.path then
		checked(uv.fs_copyfile(clip.path, dest, { excl = true }))
		return
	end
	local fd = checked(uv.fs_open(dest, "wx", 384))
	local ok, err = pcall(function()
		local offset = 0
		while offset < #clip.data do
			local written = checked(uv.fs_write(fd, clip.data:sub(offset + 1), offset))
			if written == 0 then
				error("Could not finish writing clipboard image.")
			end
			offset = offset + written
		end
	end)
	local closed, close_err = uv.fs_close(fd)
	if not ok or not closed then
		uv.fs_unlink(dest)
		error(err or close_err)
	end
end

local function replace(clip, dest)
	if (clip.ext or extension(clip.path)):lower() ~= extension(dest):lower() then
		error("Replacement must have the same extension as the old figure; files are not converted.")
	end
	if clip.path and uv.fs_realpath(clip.path) == uv.fs_realpath(dest) then
		error("Source and existing figure are the same file.")
	end
	if uv.fs_lstat(dest).type ~= "file" then
		error("Refusing to replace a symlink or non-regular file.")
	end
	local grave = vim.fs.dirname(dest) .. "/.graveyard"
	vim.fn.mkdir(grave, "p")
	local ext = extension(dest)
	local suffix = ext ~= "" and "." .. ext or ""
	local base = vim.fs.basename(dest)
	local archive = unique(grave, base:sub(1, #base - #suffix) .. "_", suffix)
	-- Stage before touching the old file. Exclusive copies prevent clobbering;
	-- rename commits atomically on the same filesystem. Archive survives failure.
	local stage = unique(vim.fs.dirname(dest), ".file-paste-", ".tmp")
	copy_source(clip, stage)
	local ok, err = uv.fs_copyfile(dest, archive, { excl = true })
	if not ok then
		uv.fs_unlink(stage)
		error(err)
	end
	ok, err = uv.fs_rename(stage, dest)
	if not ok then
		uv.fs_unlink(stage)
		error(err .. "; old figure retained; backup: " .. archive)
	end
	return archive
end

local function begin(clip, before)
	if busy then
		return true
	end
	if clip.error then
		warn(clip.error)
		return true
	end
	local buf, win = api.nvim_get_current_buf(), api.nvim_get_current_win()
	local filename = api.nvim_buf_get_name(buf)
	if filename == "" or vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable then
		warn("Use a named, editable file buffer first.")
		return true
	end
	local row = api.nvim_win_get_cursor(win)[1]
	local tick = api.nvim_buf_get_changedtick(buf)
	local line = api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
	local dir, tex = vim.fs.dirname(filename), vim.bo[buf].filetype == "tex"
	local root, dirs, oldref = dir, {}, nil
	local ok, err = pcall(function()
		if tex then
			local main
			root, main = project(buf, dir)
			dirs = graphic_dirs(root, main)
			oldref = uncomment(line):match("\\includegraphics%*?%s*%b[]%s*{([^}]+)}")
				or uncomment(line):match("\\includegraphics%*?%s*{([^}]+)}")
		end
	end)
	if not ok then
		warn(tostring(err))
		return true
	end
	local function valid()
		if not api.nvim_buf_is_valid(buf) or api.nvim_buf_get_changedtick(buf) ~= tick then
			error("Buffer changed while prompting; paste again.")
		end
		if not vim.bo[buf].modifiable then
			error("Buffer is no longer editable.")
		end
	end
	local function guard(fn)
		local success, failure = pcall(fn)
		busy = false
		if not success then
			warn(tostring(failure))
		end
	end
	busy = true
	if oldref then
		local dest
		local bases = { root }
		vim.list_extend(bases, dirs)
		local exts = extension(oldref) ~= "" and { "" } or { "", ".pdf", ".png", ".jpg", ".jpeg", ".eps", ".svg" }
		for _, base in ipairs(bases) do
			for _, ext in ipairs(exts) do
				local path = join(base, oldref .. ext)
				if uv.fs_stat(path) and uv.fs_stat(path).type == "file" then
					dest = path
					break
				end
			end
			if dest then
				break
			end
		end
		if not dest then
			busy = false
			warn("Cannot locate existing figure: " .. oldref)
			return true
		end
		dialog("Replace figure " .. vim.fs.basename(dest) .. "?", false, function(yes)
			guard(function()
				if not yes then
					return
				end
				valid()
				local archive = replace(clip, dest)
				vim.notify("Replaced " .. dest .. "\nPrevious figure: " .. archive)
			end)
		end)
		return true
	end
	local display_name = clip.path and vim.fs.basename(clip.path) or ("clipboard image." .. clip.ext)
	dialog("Upload " .. display_name .. " to this project?", false, function(yes)
		if not yes then
			busy = false
			return
		end
		local title = clip.path and ("File name (blank = " .. display_name .. ")") or "File name (blank = automatic)"
		dialog(title, true, function(name)
			guard(function()
				if name == nil then
					return
				end
				valid()
				local ext = clip.ext or extension(clip.path)
				local suffix = ext ~= "" and "." .. ext or ""
				local image = graphics[ext:lower()]
				local targetdir = tex and image and (dirs[1] or dir) or dir
				name = vim.trim(name)
				local dest
				if name == "" then
					if clip.path then
						local basename = vim.fs.basename(clip.path)
						dest = join(targetdir, basename)
						if exists(dest) then
							dest = unique(targetdir, basename:sub(1, #basename - #suffix) .. "_", suffix)
						end
					else
						dest = unique(targetdir, "pasted_image_" .. os.date("%Y%m%d"), suffix)
					end
				else
					if name == "." or name == ".." or name:find("[/\\%c]") then
						error("Enter a file name without a directory.")
					end
					if extension(name) == "" then
						name = name .. suffix
					end
					if extension(name):lower() ~= ext:lower() then
						error("Keep the original file extension: " .. suffix)
					end
					dest = join(targetdir, name)
				end
				local ref = tex and relative(dest, root) or nil
				if tex and image and dirs[1] then
					ref = vim.fs.basename(dest)
				end
				if ref and ref:find("[%%#{}\\~%^]") then
					error("Filename/path contains unsupported TeX special characters.")
				end
				local lines
				if tex and image then
					local label = vim.fs.basename(dest)
					lines = {
						"\\begin{figure}",
						"    \\centering",
						"    \\includegraphics[width=0.5\\linewidth]{" .. ref .. "}",
						"    \\caption{Enter Caption}",
						"    \\label{fig:" .. label .. "}",
						"\\end{figure}",
					}
				elseif tex and ext:lower() == "tex" then
					lines = { "\\input{" .. ref .. "}" }
				end
				vim.fn.mkdir(targetdir, "p")
				copy_source(clip, dest)
				if lines then
					local at = before and row - 1 or row
					local blank = line:match("^%s*$") ~= nil
					local inserted, reason =
						pcall(api.nvim_buf_set_lines, buf, blank and row - 1 or at, blank and row or at, false, lines)
					if not inserted then
						uv.fs_unlink(dest)
						error(reason)
					end
				end
				vim.notify("Copied file to " .. dest)
			end)
		end)
	end)
	return true
end

function M.setup()
	if M.configured then
		return
	end
	M.configured = true
	api.nvim_create_user_command("PasteFile", function()
		local clip = clipboard()
		if clip then
			begin(clip)
		else
			warn("No copied file found (requires xclip or wl-paste).")
		end
	end, { desc = "Import a file copied in a file manager" })
	for _, key in ipairs({ "p", "P" }) do
		vim.keymap.set("n", key, function()
			local reg, count = vim.v.register, vim.v.count1
			local system = reg == "+" or (reg == '"' and vim.o.clipboard:find("unnamedplus", 1, true))
			local clip = system and clipboard() or nil
			if clip then
				begin(clip, key == "P")
			else
				local ok, err = pcall(vim.cmd.normal, { args = { '"' .. reg .. count .. key }, bang = true })
				if not ok then
					if tostring(err):find("E353:", 1, true) then
						warn("Nothing to paste: no supported clipboard file or text in the selected register.")
					else
						warn(tostring(err))
					end
				end
			end
		end, { desc = "Paste text or import a clipboard file" })
	end
	vim.keymap.set("i", "<C-r>+", function()
		local clip = clipboard()
		if clip then
			vim.schedule(function()
				begin(clip)
			end)
			return ""
		end
		return "<C-r>+"
	end, { expr = true, desc = "Paste clipboard text or file" })
	local original, pending, candidate = vim.paste, nil, nil
	vim.paste = function(lines, phase)
		if phase == -1 or phase == 1 then
			local mode = api.nvim_get_mode().mode
			candidate = not busy and (mode == "n" or mode:sub(1, 1) == "i") and clipboard() or nil
			pending = candidate and {} or nil
		end
		if not pending then
			return original(lines, phase)
		end
		pending[#pending + 1] = { lines = vim.deepcopy(lines), phase = phase }
		if phase ~= -1 and phase ~= 3 then
			return true
		end
		local parts = {}
		for _, chunk in ipairs(pending) do
			parts[#parts + 1] = table.concat(chunk.lines, "\n")
		end
		local text = vim.trim(table.concat(parts)):gsub("\r\n", "\n")
		local clip, chunks = candidate, pending
		candidate, pending = nil, nil
		if
			clip.path
			and (
				text == clip.uri
				or text == clip.path
				or text == vim.trim(clip.raw):gsub("\r\n", "\n")
				or text == vim.fn.shellescape(clip.path)
				or text == '"' .. clip.path .. '"'
			)
		then
			vim.schedule(function()
				begin(clip)
			end)
			return true
		end
		for _, chunk in ipairs(chunks) do
			if original(chunk.lines, chunk.phase) == false then
				return false
			end
		end
		return true
	end
end
return M
