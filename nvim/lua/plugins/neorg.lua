return {
	"nvim-neorg/neorg",
	lazy = false,
	version = "*",
	opts = {
		load = {
			["core.defaults"] = {},
			["core.concealer"] = {},
			["core.dirman"] = {
				config = {
					default_workspace = "neorg",
					workspaces = {
						neorg = "~/Documents/neorg",
					},
					index = "index.norg",
					autochdir = true
				},
			},
		}
	},
	config = true
}
