local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
    -- LSP
    'neovim/nvim-lspconfig',
    -- Treesitter
    { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },

    -- Fzf
    'nvim-lua/plenary.nvim',
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.1',
        dependencies = { 'nvim-lua/plenary.nvim' }
    },

    -- Autocomplete
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/nvim-cmp',
    'ray-x/lsp_signature.nvim',
    {
        'Exafunction/codeium.vim',
        config = function()
            -- Change '<C-g>' here to any keycode you like.
            vim.keymap.set('i', '<M-a>', function() return vim.fn['codeium#Accept']() end, { expr = true })
        end
    },
    -- Snippets (luasnip)
    {
        'L3MON4D3/LuaSnip',
        version = '1.*',
        build = 'make install_jsregexp'
    },
    'saadparwaiz1/cmp_luasnip',
    -- Autopair
    'tmsvg/pear-tree',
    'kylechui/nvim-surround',
    -- Explorer
    'kyazdani42/nvim-tree.lua',
    'kyazdani42/nvim-web-devicons',
    -- Line
    'nvim-lualine/lualine.nvim',
    -- Colorscheme
    'folke/tokyonight.nvim',
    'catppuccin/nvim',
    -- Markdown
    { "iamcco/markdown-preview.nvim",    build = function() vim.fn["mkdp#util#install"]() end },
    { 'numToStr/Comment.nvim',           config = function() require('Comment').setup() end },
}

local opts    = {}

require("lazy").setup(plugins, opts)
