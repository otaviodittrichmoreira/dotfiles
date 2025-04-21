return {
	"lervag/vimtex",
	lazy = false, -- Load the plugin immediately
	init = function()
		vim.g.vimtex_syntax_enabled = 1 -- Enable syntax highlighting
		vim.wo.conceallevel = 2 -- Enable conceal level
		vim.g.vimtex_quickfix_open_on_warning = 0
		vim.g.vimtex_view_method = "zathura"
		vim.g.vimtex_view_general_viewer = "zathura"
		vim.g.vimtex_view_general_options = "-reuse-instance -forward-search @tex @line @pdf"
		vim.g.vimtex_view_forward_search_on_start = 1
	end,
}
