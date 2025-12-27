return {
	"let-def/texpresso.vim",
	config = function()
		vim.cmd([[:lua require('texpresso').texpresso_path = "/home/otaviomoreira/repos/texpresso/build/texpresso"]])
	end,
}
