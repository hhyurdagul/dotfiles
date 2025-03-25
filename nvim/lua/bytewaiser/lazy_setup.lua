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
    -- Colorscheme
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        opts = {
            color_overrides = {
                mocha = {
                    base = "#000000",
                    mantle = "#000000",
                    crust = "#000000",
                },
            },
        }
    },
    -- {
    --     "folke/tokyonight.nvim",
    --     lazy = false,
    --     priority = 1000,
    --     opts = {style = "night"},
    -- },
    -- Detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',
    -- Interactive Repls over Neovim
    -- require 'bytewaiser.plugins.iron',

    -- Highlight todo, notes, etc in comments
    { 'folke/todo-comments.nvim',            event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

    -- AI
    {
        'Exafunction/codeium.vim',
        config = function()
            -- Change '<C-g>' here to any keycode you like.
            vim.keymap.set('i', '<C-a>', function() return vim.fn['codeium#Accept']() end, { expr = true, silent = true })
            vim.keymap.set('i', '<C-l>', function() return vim.fn['codeium#CycleCompletions'](1) end,
                { expr = true, silent = true })
            vim.keymap.set('i', '<C-h>', function() return vim.fn['codeium#CycleCompletions'](-1) end,
                { expr = true, silent = true })
            vim.keymap.set('i', '<C-x>', function() return vim.fn['codeium#Clear']() end, { expr = true, silent = true })
        end
    },

    {
        "dustinblackman/oatmeal.nvim",
        cmd = { "Oatmeal" },
        keys = {
            { "<leader>om", mode = "n", desc = "Start Oatmeal session" },
        },
        opts = {
            backend = "ollama",
            model = "llama3:latest",
        },
    },

    -- Language server protocol
    require 'bytewaiser.plugins.lsp',
    -- Treesitter
    require 'bytewaiser.plugins.treesitter',

    { "lukas-reineke/indent-blankline.nvim", main = "ibl",       opts = {} },
    -- Fzf
    require 'bytewaiser.plugins.telescope',

    -- Autocomplete & Snippets
    require 'bytewaiser.plugins.autocomplete',
    -- 'ray-x/lsp_signature.nvim',


    -- {
    --     'huggingface/llm.nvim'
    -- },

    -- Autopair
    'tmsvg/pear-tree',
    'kylechui/nvim-surround',
    -- Explorer
    'kyazdani42/nvim-tree.lua',
    'kyazdani42/nvim-web-devicons',
    -- Line
    'nvim-lualine/lualine.nvim',
    -- Markdown
    { "iamcco/markdown-preview.nvim", build = function() vim.fn["mkdp#util#install"]() end },

    -- Auto Comment
    { 'numToStr/Comment.nvim',        config = function() require('Comment').setup() end },

    -- {                       -- Useful plugin to show you pending keybinds.
    --     'folke/which-key.nvim',
    --     event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    --     config = function() -- This is the function that runs, AFTER loading
    --         require('which-key').setup()
    --
    --         -- Document existing key chains
    --         require('which-key').register {
    --             ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
    --             ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
    --             ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
    --             ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
    --             ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
    --             ['<leader>t'] = { name = '[T]oggle', _ = 'which_key_ignore' },
    --             ['<leader>h'] = { name = 'Git [H]unk', _ = 'which_key_ignore' },
    --             ['<leader>g'] = { name = '[G]o', _ = 'which_key_ignore' },
    --         }
    --         -- visual mode
    --         require('which-key').register({
    --             ['<leader>h'] = { 'Git [H]unk' },
    --         }, { mode = 'v' })
    --     end,
    -- },

}

local opts    = {}

require("lazy").setup(plugins, opts)
