return {
	"nvim-tree/nvim-tree.lua",
	lazy = false,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	keys = {
		{ "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Opens Nvim Tree" },
	},
	opts = {
		disable_netrw = true,
		hijack_netrw = true,
	},
}
