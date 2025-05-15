return { -- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		local configs = require("nvim-treesitter.configs")

		configs.setup({
			ensure_installed = {
				"bash",
				"c",
				"cpp",
				"css",
				"dockerfile",
				"gitignore",
				"go",
				"html",
				"javascript",
				"json",
				"lua",
				"zig",
				"make",
				"markdown",
				"markdown_inline",
				"latex",
				"python",
				"rust",
				"svelte",
				"toml",
				"tsx",
				"typescript",
				"vim",
				"typst",
				"norg"
			},
			sync_install = false,
			highlight = {
				enable = true,

				disable = function(lang, buf)
					local max_filesize = 100 * 1024 -- 100 KB
					local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > max_filesize then
						return true
					end
				end,
				additional_vim_regex_highlighting = false,
			},
			indent = { enable = true },
			auto_install = false,
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = ",", -- set to `false` to disable one of the mappings
					node_incremental = ",",
					scope_incremental = false,
					node_decremental = "<Backspace>",
				},
			},
		})

		vim.treesitter.language.register("markdown", { "vimwiki" })
	end,
}
