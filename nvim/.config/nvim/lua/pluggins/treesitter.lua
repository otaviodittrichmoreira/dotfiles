return {
  -- Tree-sitter plugin
  "nvim-treesitter/nvim-treesitter",
  build = function()
    -- Check if Tree-Sitter CLI is installed, otherwise install it
    local is_installed = vim.fn.executable("tree-sitter") == 1
    if not is_installed then
      vim.fn.system("npm install -g tree-sitter-cli")
    end
  end,
  config = function()
    require'nvim-treesitter.configs'.setup {
      ensure_installed = { "latex" }, -- Add other parsers as needed
      highlight = { enable = true },
    }
  end,
}
