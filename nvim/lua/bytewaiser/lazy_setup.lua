local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable", -- latest stable release
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

local plugins = {
    -- Detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',

    -- Language server protocol
    require 'bytewaiser.plugins.lsp',
    -- Treesitter
    { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },

    -- Fzf
    'nvim-lua/plenary.nvim',
    require 'bytewaiser.plugins.telescope',


    -- Autocomplete
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/nvim-cmp',
    'ray-x/lsp_signature.nvim',

    -- AI
    {
        'Exafunction/codeium.vim',
        config = function()
            -- Change '<C-g>' here to any keycode you like.
            vim.keymap.set('i', '<M-a>', function() return vim.fn['codeium#Accept']() end, { expr = true })
            vim.keymap.set('i', '<M-Right>', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true })
            vim.keymap.set('i', '<M-Left>', function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true })
        end
    },

    -- {
    --     'huggingface/llm.nvim'
    -- },
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

    -- Auto Comment
    { 'numToStr/Comment.nvim',           config = function() require('Comment').setup() end },

    {                   -- Useful plugin to show you pending keybinds.
        'folke/which-key.nvim',
        event = 'VimEnter', -- Sets the loading event to 'VimEnter'
        config = function() -- This is the function that runs, AFTER loading
            require('which-key').setup()

            -- Document existing key chains
            require('which-key').register {
                ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
                ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
                ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
                ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
                ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
                ['<leader>t'] = { name = '[T]oggle', _ = 'which_key_ignore' },
                ['<leader>h'] = { name = 'Git [H]unk', _ = 'which_key_ignore' },
                ['<leader>g'] = { name = '[G]o', _ = 'which_key_ignore' },
            }
            -- visual mode
            require('which-key').register({
                ['<leader>h'] = { 'Git [H]unk' },
            }, { mode = 'v' })
        end,
    },


    -- Tmux
    {
        "christoomey/vim-tmux-navigator",
        cmd = {
            "TmuxNavigateLeft",
            "TmuxNavigateDown",
            "TmuxNavigateUp",
            "TmuxNavigateRight",
            "TmuxNavigatePrevious",
        },
        keys = {
            { "<C-h>",  "<cmd><C-U>TmuxNavigateLeft<cr>" },
            { "<C-j>",  "<cmd><C-U>TmuxNavigateDown<cr>" },
            { "<C-k>",  "<cmd><C-U>TmuxNavigateUp<cr>" },
            { "<C-l>",  "<cmd><C-U>TmuxNavigateRight<cr>" },
            { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
        },
    }
}

local opts    = {}

require("lazy").setup(plugins, opts)
