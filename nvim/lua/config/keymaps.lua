vim.keymap.set("n", "ğ", "[", { remap = true })
vim.keymap.set("n", "ü", "]", { remap = true })

vim.keymap.set("v", "p", "_dP", { remap = false })

vim.keymap.set("n", "<leader>f", function()
	require("conform").format()
end, { desc = "Format current file" })
