return {
	"ibhagwan/fzf-lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	keys = {
		{ "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Opens Fzf File picker" },
		{ "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Opens Fzf Live grep picker" },
	},
	opts = {},
}
