vim.lsp.config("ruff", {
	init_options = {
		settings = {
			-- Ruff language server settings go here
		},
	},
})

vim.lsp.enable("ruff")

vim.lsp.config("pyright", {
	settings = {
		pyright = {
			disableOrganizeImports = true,
		},
		python = {
			analysis = {
				ignore = { "*" },
			},
		},
	},
})

vim.lsp.enable("pyright")

vim.lsp.config("ruff", {
	cmd = { "ruff", "server" },
	filetypes = { "python" },
	root_dir = function(bufnr, on_dir)
		local root = vim.fs.root(bufnr, { "pyproject.toml", ".git" })
		if root then
			on_dir(root)
		end
	end,
})

vim.lsp.enable("ruff")
