require("kickstart")
require("pluggins.ultisnips")
require("mini.align").setup()
require("mini.surround").setup()
require("mini.jump").setup()
require("mini.move").setup()
require("mini.operators").setup()
require("mini.splitjoin").setup()
require("mini.icons").setup()
require("mini.starter").setup()
require("keymaps")
require("ruff")
require("settings")

vim.api.nvim_create_autocmd("FileType", {
	pattern = "tex",
	callback = function()
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.expandtab = true
	end,
})

-- Silence the specific position encoding message
local notify_original = vim.notify
vim.notify = function(msg, ...)
	if
		msg
		and (
			msg:match("position_encoding param is required")
			or msg:match("Defaulting to position encoding of the first client")
			or msg:match("multiple different client offset_encodings")

		)
	then
		return
	end
	return notify_original(msg, ...)
end
