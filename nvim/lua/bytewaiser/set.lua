vim.g.mapleader = " "
vim.g.codeium_disable_bindings = 1

vim.opt.ts = 4
vim.opt.shiftwidth = 4
vim.opt.ai = true
vim.opt.sw = 4
vim.opt.number = true
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.wrap = false
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true
vim.opt.ttyfast = true
vim.opt.swapfile = false


vim.opt.backupdir = vim.fn.stdpath("cache") .. "/backup"
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"
vim.opt.undofile = true
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.termguicolors = true
vim.opt.compatible = false

vim.opt.syntax = "on"
vim.opt.filetype.plugin = "on"

vim.cmd("colorscheme catppuccin")
vim.cmd[[
    highlight Normal guibg=NONE ctermbg=NONE
    highlight NonText guibg=NONE ctermbg=NONE
]]
