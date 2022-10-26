-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'
    -- LSP
    use 'neovim/nvim-lspconfig'
    -- Treesitter
    use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
    -- Autocomplete
    use 'hrsh7th/cmp-nvim-lsp'
    use 'hrsh7th/cmp-buffer'
    use 'hrsh7th/cmp-path'
    use 'hrsh7th/cmp-cmdline'
    use 'hrsh7th/nvim-cmp'
    -- Snippets (vsnip) # Might change to luasnip
    use 'hrsh7th/cmp-vsnip'
    use 'hrsh7th/vim-vsnip'
    -- Telescope
    use 'nvim-lua/plenary.nvim'
    use 'nvim-telescope/telescope.nvim'
    -- Autopair
    use 'tmsvg/pear-tree'
    use {'kylechui/nvim-surround', config = function() require("nvim-surround").setup({}) end}
    -- Explorer
    use 'kyazdani42/nvim-tree.lua'
    use 'kyazdani42/nvim-web-devicons'
    -- Line
    use 'nvim-lualine/lualine.nvim'
    -- Colorscheme
    use 'folke/tokyonight.nvim'
    use { 'catppuccin/nvim', as = "catppuccin" }
    -- Markdown
    use { "iamcco/markdown-preview.nvim", run = function() vim.fn["mkdp#util#install"]() end }
end)
