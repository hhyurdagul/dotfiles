vim.keymap.set("n", "ğ", "[", { remap = true })
vim.keymap.set("n", "ü", "]", { remap = true })

vim.keymap.set("v", "p", '"_dP', { remap = false })

vim.keymap.set("n", "<leader>f", function()
	require("conform").format({ timeout_ms = 500, lsp_format = "fallback" })
end, { desc = "Format current file" })

vim.keymap.set("n", "<leader>ww", "<CMD>cd ~/Documents/neorg/<CR><CMD>Neorg index<CR>", { remap = true })


-- Markdown Task Toggler Configuration
-- Define a function to toggle the markdown task list item
local function toggle_task()
	-- Get the current cursor position (row, col)
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))

	-- Get the line at the current cursor position
	local line = vim.api.nvim_get_current_line()

	-- Check if the line contains a markdown task item
	-- This uses a simple pattern match for "[ ]" or "[x]"
	if line:match("^(- %[[ ]%])") then
		-- If it's "[ ]", replace it with "[x]"
		local new_line = line:gsub("^(- %[[ ]%])", "- [x]")
		vim.api.nvim_set_current_line(new_line)
	elseif line:match("^(- %[x%])") then
		-- If it's "[x]", replace it with "[ ]"
		local new_line = line:gsub("^(- %[x%])", "- [ ]")
		vim.api.nvim_set_current_line(new_line)
	end
end

-- Create a keymap for the toggle function
-- 'n' is for normal mode, 'i' is for insert mode
vim.keymap.set({ 'n', 'i' }, '<C-Enter>', toggle_task, { desc = "Toggle Markdown Task Item" })
