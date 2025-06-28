return {
	"lervag/vimtex",
	lazy = false, -- Load the plugin immediately
	init = function()
		vim.g.vimtex_syntax_enabled = 1 -- Enable syntax highlighting
		vim.wo.conceallevel = 2 -- Enable conceal level
		vim.g.vimtex_quickfix_open_on_warning = 0
		vim.g.vimtex_view_method = "general"
		vim.g.vimtex_view_general_viewer = "evince"
		vim.g.vimtex_view_general_options = "-reuse-instance -forward-search @tex @line @pdf"
		vim.g.vimtex_view_forward_search_on_start = 1
		vim.g.vimtex_compiler_latexmk = {
			build_dir = "",
			options = {
				"-pdf",
				"-pdflatex=lualatex",
				"-interaction=nonstopmode",
			},
		}
	end,
}
