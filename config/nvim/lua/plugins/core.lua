return {
	-- Detect tabstop and shiftwidth automatically
	"tpope/vim-sleuth",

	-- Autopair
	"tmsvg/pear-tree",
	"kylechui/nvim-surround",

	-- Highlight todo, notes, etc in comments
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	}

}
