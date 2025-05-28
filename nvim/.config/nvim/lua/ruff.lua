vim.lsp.config("ruff", {
	init_options = {
		settings = {
			-- Ruff language server settings go here
		},
	},
})

vim.lsp.enable("ruff")

require("lspconfig").pyright.setup({
	settings = {
		pyright = {
			-- Using Ruff's import organizer
			disableOrganizeImports = true,
		},
		python = {
			analysis = {
				-- Ignore all files for analysis to exclusively use Ruff for linting
				ignore = { "*" },
			},
		},
	},
})
