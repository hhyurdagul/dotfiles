call plug#begin(stdpath("data") . "/plugged")
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'
Plug 'nvim-lualine/lualine.nvim'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'kyazdani42/nvim-tree.lua'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'tmsvg/pear-tree'
Plug 'ayu-theme/ayu-vim'
call plug#end()

let mapleader=" "
set ts=4
set shiftwidth=4
set ai sw=4
set expandtab
set autoindent
set relativenumber
set nowrap
set mouse=a
set clipboard=unnamedplus
set cursorline
set ttyfast
set noswapfile

set backupdir=~/.cache/nvim/backup
set undodir=~/.cache/nvim/undo
set undofile
set completeopt=menu,menuone,noselect
set termguicolors
let ayucolor="dark"
colorscheme ayu

nnoremap <leader>e :NvimTreeToggle<CR>

source $HOME/.config/nvim/lsp.lua
source $HOME/.config/nvim/tree.lua
source $HOME/.config/nvim/cmp.lua
source $HOME/.config/nvim/status.lua
source $HOME/.config/nvim/pair.vim
source $HOME/.config/nvim/find.vim
