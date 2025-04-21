vim.keymap.set("n", "ğ", "[", { remap = true })
vim.keymap.set("n", "ü", "]", { remap = true })

vim.keymap.set("v", "p", '"_dP', { remap = false })

vim.keymap.set("n", "<leader>f", function()
	require("conform").format({ timeout_ms = 500, lsp_format = "fallback" })
end, { desc = "Format current file" })

vim.keymap.set("n", "<leader>ww", "<cmd>cd ~/Documents/vimwiki/<cr><Plug>VimwikiIndex", { remap = true })
