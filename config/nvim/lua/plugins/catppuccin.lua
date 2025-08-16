return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	config = function()
		require("catppuccin").setup({
			color_overrides = {
				mocha = {
					base = "#000000",
					mantle = "#000000",
					crust = "#000000",
				},
			},
		})
		vim.cmd.colorscheme("catppuccin-mocha")
		-- vim.cmd([[
		-- 	highlight Normal guibg=NONE ctermbg=NONE
		-- 	highlight NonText guibg=NONE ctermbg=NONE
		-- ]])
	end,
}
