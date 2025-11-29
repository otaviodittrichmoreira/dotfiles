-- Spell Check for .tex files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "tex",
	callback = function()
		vim.opt.spell = true
		vim.opt.spelllang = "en_us"
	end,
})

-- Define 'inside value' (iv) and 'around value' (av) text objects for LaTeX equations
vim.api.nvim_set_keymap("x", "iv", [[:<C-u>lua SelectLatexValue(true, false)<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("o", "iv", [[:<C-u>lua SelectLatexValue(true, false)<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("x", "av", [[:<C-u>lua SelectLatexValue(true, true)<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("o", "av", [[:<C-u>lua SelectLatexValue(true, true)<CR>]], { noremap = true, silent = true })

-- Define 'inside value' (in) and 'around value' (an) text objects for LaTeX equations
vim.api.nvim_set_keymap("x", "in", [[:<C-u>lua SelectLatexValue(false, false)<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("o", "in", [[:<C-u>lua SelectLatexValue(false, false)<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("x", "an", [[:<C-u>lua SelectLatexValue(false, true)<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap("o", "an", [[:<C-u>lua SelectLatexValue(false, true)<CR>]], { noremap = true, silent = true })

-- Source - https://stackoverflow.com/a
-- Posted by hookenz, modified by community. See post 'Timeline' for change history
-- Retrieved 2025-11-28, License - CC BY-SA 4.0
local function dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

local attributers = {
	["="] = true,
	["\\leq"] = true,
	["\\geq"] = true,
	["<"] = true,
	[">"] = true,
	["\\approx"] = true,
	["\\propto"] = true,
}

local function last_before(s, pattern, idx)
	local last = nil
	local start = 1
	while true do
		local i = s:find(pattern, start, true)
		if not i or i >= idx then
			return last
		end
		last = i
		start = i + 1
	end
end

local function last_before_list(s, pattern_list, idx)
	local max = 0
	for _, pattern in ipairs(pattern_list) do
		local last = last_before(s, pattern, idx)
		if last and last > max then
			max = last
		end
	end
	return max
end

local function find_attributer_bool(s)
	local depth = 0
	local depth_curly = 0
	local depth_curly2 = 0
	local equal_list = {}

	for i = 1, #s do
		local c = s:sub(i, i)
		local c_long = s:sub(i, math.min(#s, i + 3))
		local c_extra = s:sub(i, math.min(#s, i + 6))
		local c_before = s:sub(math.max(i - 1, 1), i)

		if c_before == "\\(" or c_before == "\\)" then
		elseif c == "(" or c == "[" then
			depth = depth + 1
		elseif c == ")" or c == "]" then
			depth = math.max(depth - 1, 0)
		elseif c_before == "\\{" then
			depth_curly = depth_curly + 1
		elseif c_before == "\\}" then
			depth_curly = math.max(depth_curly - 1, 0)
		elseif c == "{" then
			depth_curly2 = depth_curly2 + 1
		elseif c == "}" then
			depth_curly2 = math.max(depth_curly2 - 1, 0)
		elseif attributers[c_extra] then
			if depth == 0 and depth_curly == 0 then
				return true
			end
		elseif attributers[c_long] then
			if depth == 0 and depth_curly == 0 and depth_curly2 == 0 then
				return true
			end
		elseif attributers[c] then
			if depth == 0 and depth_curly == 0 and depth_curly2 == 0 then
				return true
			end
		end
	end

	return false
end

local function find_attributer(s)
	local depth = 0
	local depth_curly = 0
	local depth_curly2 = 0
	local equal_list = {}

	for i = 1, #s do
		local c = s:sub(i, i)
		local c2 = s:sub(i, i + 1)
		local c_long = s:sub(i, math.min(#s, i + 3))
		local c_extra = s:sub(i, math.min(#s, i + 6))
		local c_before = s:sub(math.max(i - 1, 1), i)

		if c_before == "\\(" or c_before == "\\)" then
		elseif c == "(" or c == "[" then
			depth = depth + 1
		elseif c == ")" or c == "]" then
			depth = math.max(depth - 1, 0)
		elseif c_before == "\\{" then
			depth_curly = depth_curly + 1
		elseif c_before == "\\}" then
			depth_curly = math.max(depth_curly - 1, 0)
		elseif c == "{" then
			depth_curly2 = depth_curly2 + 1
		elseif c == "}" then
			depth_curly2 = math.max(depth_curly2 - 1, 0)
		elseif attributers[c_extra] then
			if depth == 0 and depth_curly == 0 then
				table.insert(equal_list, { i, i + 6 })
			end
		elseif attributers[c_long] then
			if depth == 0 and depth_curly == 0 and depth_curly2 == 0 then
				table.insert(equal_list, { i, i + 3 })
			end
		elseif attributers[c] then
			if depth == 0 and depth_curly == 0 and depth_curly2 == 0 then
				table.insert(equal_list, { i, i })
			end
		end
	end

	return equal_list
end

local function find_delimiter_containing_attributer(s, start, open, close)
	local open_idx = 1
	local close_idx
	local has_attributer

	local max_iter = 500
	local i = 0
	while not has_attributer and open_idx and i < max_iter do
		open_idx = s:find(open, start, true)
		if open_idx then
			open_idx = open_idx + #open
			_, close_idx = s:find(close, open_idx, true)
			if close_idx then
				close_idx = close_idx - #close
				has_attributer = find_attributer_bool(s:sub(open_idx, close_idx))
				start = close_idx + 2
			end
		end
		i = i + 1
	end
	return open_idx, close_idx
end

local function find_delimiter_containing_attributer_list(s, start, delimiter_list)
	local min_open_idx, min_close_idx = 999999, 999999
	for _, delimiter in ipairs(delimiter_list) do
		local open, close = delimiter[1], delimiter[2]
		local open_idx, close_idx = find_delimiter_containing_attributer(s, start, open, close)
		if open_idx and close_idx and open_idx < min_open_idx then
			min_open_idx = open_idx
			min_close_idx = close_idx
		end
	end
	return min_open_idx, min_close_idx
end

local function find_two_lower_two_upper(pairs_list, x)
	local lower1, lower2 = nil, nil -- largest and 2nd largest < x
	local upper1, upper2 = nil, nil -- smallest and 2nd smallest > x

	for _, pair in ipairs(pairs_list) do
		local a = pair[1]

		-- LOWER numbers
		if a <= x then
			if (not lower1) or (a > lower1[1]) then
				lower2 = lower1
				lower1 = pair
			elseif (not lower2) or (a > lower2[1]) then
				lower2 = pair
			end
		end

		-- UPPER numbers
		if a > x then
			if (not upper1) or (a < upper1[1]) then
				upper2 = upper1
				upper1 = pair
			elseif (not upper2) or (a < upper2[1]) then
				upper2 = pair
			end
		end
	end

	return lower1, lower2, upper1, upper2
end

local function in_multiline_math(row, col)
	return (
		vim.fn["vimtex#syntax#in"]("texMathZoneEnv", row, col) == 1
		and vim.fn["vimtex#syntax#in"]("texCmdMathEnv", row, col) == 0
	)
		or (vim.fn["vimtex#syntax#in"]("texMathZoneLD", row, col) == 1 and vim.fn["vimtex#syntax#in"](
			"texMathDelimZoneLD",
			row,
			col
		) == 0)
		or (
			vim.fn["vimtex#syntax#in"]("texMathZoneTD", row, col) == 1
			and vim.fn["vimtex#syntax#in"]("texMathDelimZoneTD", row, col) == 0
		)
end

local function in_math_zone(row, col)
	return vim.fn["vimtex#syntax#in_mathzone"](row, col) == 1
		or vim.fn["vimtex#syntax#in"]("texMathDelimZoneLI", row, col) == 1
		or vim.fn["vimtex#syntax#in"]("texMathDelimZoneTI", row, col) == 1
end

function SelectLatexValue(after, around)
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	-- col is one less than it shouldl for some reason
	col = col + 1
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
	local max_row_check = 50
	local last_visible = vim.fn.line("w$")
	local i = 1
	while line and not _SelectLatexValue(line, row, col, after, around) and row < last_visible and i < max_row_check do
		row = row + 1
		col = 1
		line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
		i = i + 1
	end
end

function _SelectLatexValue(line, row, col, after, around)
	-- Is in math zone and is in multiline math bools
	local inside_math_zone = in_math_zone(row, col)
	local inside_multiline_math = in_multiline_math(row, col)

	-- Start point to look for delimiters/attributers
	local start_search_col
	if inside_multiline_math then
		start_search_col = 0
	elseif inside_math_zone then
		start_search_col = last_before_list(line, { "\\(", "$" }, col)
		if start_search_col == nil then
			return false
		end
	else
		start_search_col = col
	end

	-- Locate start and end the next math zone with a unenclosed delimiter inside
	local open_math, close_math, math_part
	if not inside_multiline_math then
		open_math, close_math =
			find_delimiter_containing_attributer_list(line, start_search_col, { { "\\(", "\\)" }, { "$", "$" } })
		if open_math == nil or close_math == nil then
			return false
		end
		math_part = line:sub(open_math, close_math)
	else
		open_math, close_math = 1, #line
		math_part = line
	end

	-- Cursor column relative to math part
	local relative_col = col - open_math

	-- Get all attributer positions
	local attributers_list = find_attributer(math_part)

	-- Two attributers before cursor, two after
	local lower1, lower2, upper1, upper2 = find_two_lower_two_upper(attributers_list, relative_col)
	if lower1 == nil and lower2 == nil and upper1 == nil and upper2 == nil then
		return false
	end

	-- Position of the attributer in the middle of the selection
	local middle_attributer, bottom, top
	if lower1 ~= nil and upper1 == nil then
		middle_attributer = lower1
		top = #math_part
		if lower2 == nil then
			bottom = 1
		else
			bottom = lower2[2] + 1
		end
	elseif lower1 == nil and upper1 ~= nil then
		middle_attributer = upper1
		bottom = 1
		if upper2 == nil then
			top = #math_part
		else
			top = upper2[1] - 1
		end
	elseif lower1 ~= nil and upper1 ~= nil then
		middle_attributer = lower1
		top = upper1[1] - 1
		if lower2 == nil then
			bottom = 1
		else
			bottom = lower2[2] + 1
		end
	end

	--------------------------------------------------------
	--                4 POINTS OF INTEREST                --
	--                                                    --
	--    * Simple case                                   --
	--    \(a + b \leq&\ 3 + b + f(x)\)                   --
	--      ^    ^      ^           ^                     --
	--      1    2      3           4                     --
	--                                                    --
	--    * Multiple attributers                          --
	--                       cursor here -> |             --
	--    \(a + b \leq c + d + \int x dx = x^2 = e^x\)    --
	--                ^                 ^ ^   ^           --
	--                1                 2 3   4           --
	--                                                    --
	--------------------------------------------------------

	local point1, point2, point3, point4 = bottom, middle_attributer[1] - 1, middle_attributer[2] + 1, top

	-- Change to absolute coordinates
	point1 = point1 + open_math - 1
	point2 = point2 + open_math - 1
	point3 = point3 + open_math - 1
	point4 = point4 + open_math - 1

	-- Remove trailing spaces
	while line:sub(point1, point1) == " " do
		point1 = point1 + 1
	end
	while line:sub(point2, point2) == " " do
		point2 = point2 - 1
	end
	while line:sub(point3, point3) == " " do
		point3 = point3 + 1
	end
	while line:sub(point4, point4) == " " do
		point4 = point4 - 1
	end

	-- Remove \\ in multiline math if not using around
	if not around and line:sub(point4 - 1, point4) == "\\\\" then
		point4 = point4 - 2
	end
	while line:sub(point4, point4) == " " do
		point4 = point4 - 1
	end

	-- Remove & and \ when not using around
	while
		line:sub(point3, point3) == "&"
		or line:sub(point3, point3 + 1):match("\\[^%a]")
		or line:sub(point3, point3) == " "
	do
		point3 = point3 + 1
	end
	while line:sub(point2, point2) == "&" or line:sub(point2, point2) == "\\" or line:sub(point2, point2) == " " do
		point2 = point2 - 1
	end

	local left, right
	if not around then
		if after then
			left = point3
			right = point4
		else
			left = point1
			right = point2
		end
	else
		if after then
			left = point2 + 1
			right = point4
		else
			left = point1
			right = point3 - 1
		end
	end

	if left > right then
		return true
	end

	local quad_idx = line:sub(left, right):find("\\quad", 0, false)
	while quad_idx ~= nil do
		quad_idx = quad_idx + left - 1
		if after then
			right = SafeMin(right, quad_idx - 1)
		else
			left = SafeMax(left, quad_idx + 6)
		end
		quad_idx = line:sub(left, right):find("\\quad", 0, false)
	end

	if around then
		while line:sub(right + 1, right + 1) == " " do
			right = right + 1
		end
	else
		while line:sub(right, right) == " " do
			right = right - 1
		end
		while line:sub(left, left) == " " do
			left = left + 1
		end
	end

	vim.fn.setpos("'<", { 0, row, left, 0 })
	vim.fn.setpos("'>", { 0, row, right, 0 })
	vim.cmd("normal! gv")
	return true
end
