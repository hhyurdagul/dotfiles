local nnoremap = require("bytewaiser.keymap").nnoremap
local vnoremap = require("bytewaiser.keymap").vnoremap


nnoremap("<leader>e", "<cmd>NvimTreeToggle<cr>")
nnoremap("<leader>w", "<C-w>")

-- Find files using Telescope command-line sugar.
nnoremap("<leader>ff", "<cmd>Telescope find_files<cr>")
nnoremap("<leader>fg", "<cmd>Telescope live_grep<cr>")
nnoremap("<leader>fb", "<cmd>Telescope buffers<cr>")
nnoremap("<leader>fh", "<cmd>Telescope help_tags<cr>")

-- Paste without yanking
vnoremap("p", '"_dP')
