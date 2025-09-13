-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.codeium_disable_bindings = 1

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

vim.opt.number = true -- Line numbers

-- Relative line numbers
-- vim.opt.relativenumber = true

vim.opt.mouse = "a"      -- Mouse mode

vim.opt.showmode = false -- Dont show the mode since it is already in the statusline

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

vim.opt.undofile = true -- Save undo history

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.signcolumn = "number" -- Keep signcolumn on by default

vim.opt.updatetime = 250      -- Decrease update time

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.inccommand = "split" -- Preview substitutions live, as you type!

vim.opt.cursorline = true    -- Show which line your cursor is on

-- vim.opt.scrolloff = 5 -- Minimal number of screen lines to keep above and below the cursor.

vim.opt.expandtab = true   -- Convert tabs to spaces
vim.opt.tabstop = 4        -- How many spaces are shown per Tab
vim.opt.softtabstop = 4    -- How many spaces are shown per Tab
vim.opt.shiftwidth = 4     -- Amount to indent with > or <

vim.opt.breakindent = true -- Enable break indent
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

vim.opt.ai = true
vim.opt.wrap = false
vim.opt.ttyfast = true
vim.opt.swapfile = false

vim.opt.backupdir = vim.fn.stdpath("cache") .. "/backup"
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.termguicolors = true
vim.opt.compatible = false

vim.opt.syntax = "on"
vim.opt.filetype.plugin = "on"
