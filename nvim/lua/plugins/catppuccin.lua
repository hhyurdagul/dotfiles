return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	opts = {},
	config = function()
		vim.cmd.colorscheme("catppuccin-mocha")

		vim.cmd([[
          highlight Normal guibg=NONE ctermbg=NONE
          highlight NonText guibg=NONE ctermbg=NONE
      ]])
	end,
}
