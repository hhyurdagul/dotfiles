call plug#begin(stdpath("data") . "/plugged")
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'williamboman/nvim-lsp-installer'
Plug 'jose-elias-alvarez/nvim-lsp-ts-utils'
Plug 'tomlion/vim-solidity'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'ray-x/lsp_signature.nvim'
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'
Plug 'nvim-lualine/lualine.nvim'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'kyazdani42/nvim-tree.lua'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'tmsvg/pear-tree'
Plug 'ayu-theme/ayu-vim'
Plug 'morhetz/gruvbox'
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
Plug 'vimwiki/vimwiki'
Plug 'windwp/nvim-ts-autotag'
call plug#end()


set exrc
set secure

let mapleader=" "
set ts=4
set shiftwidth=4
set ai sw=4
set expandtab
set smartindent
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


set nocompatible
filetype plugin on
syntax on

" let ayucolor="dark"
" colorscheme ayu
colorscheme tokyonight

nnoremap <leader>e :NvimTreeToggle<CR>
" autocmd BufWritePost *.tex silent! execute "!pdflatex % >/dev/null 2>&1" 

" source $HOME/.config/nvim/lsp.lua
source $HOME/.config/nvim/lspinstaller.lua
source $HOME/.config/nvim/tree.lua
source $HOME/.config/nvim/cmp.lua
source $HOME/.config/nvim/status.lua
source $HOME/.config/nvim/pair.vim
source $HOME/.config/nvim/find.vim

autocmd FileType javascript setlocal shiftwidth=2 softtabstop=2 expandtab
autocmd FileType javascriptreact setlocal shiftwidth=2 softtabstop=2 expandtab
autocmd FileType typescriptreact setlocal shiftwidth=2 softtabstop=2 expandtab
autocmd FileType json setlocal shiftwidth=2 softtabstop=2 expandtab
autocmd FileType jsx setlocal shiftwidth=2 softtabstop=2 expandtab
autocmd FileType tsx setlocal shiftwidth=2 softtabstop=2 expandtab
