local a = {
	-- Main LSP Configuration
	"neovim/nvim-lspconfig",
	dependencies = {
		-- Automatically install LSPs and related tools to stdpath for Neovim
		-- Mason must be loaded before its dependents so we need to set it up here.
		-- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
		{ "williamboman/mason.nvim", opts = {} },
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",

		-- Useful status updates for LSP.
		{ "j-hui/fidget.nvim", opts = {} },
	},
	config = function()
		local servers = {

			html = {},
			ts_ls = {},
			jsonls = {},
			astro = {},

			gopls = {},
			clangd = {},
			rust_analyzer = {},

			lua_ls = {
				settings = {
					Lua = {
						runtime = {
							version = "LuaJIT",
						},
						diagnostics = {
							-- Get the language server to recognize the `vim` global
							globals = { "vim", "require" },
						},
					},
				},
			},
		}

		local tools = {
			"stylua", -- Used to format Lua code
			"prettierd", -- Used to format Js code
		}

		require("mason-tool-installer").setup({ ensure_installed = tools })

		require("mason-lspconfig").setup({
			ensure_installed = servers,
		})

		for server, opts in pairs(servers) do
			vim.lsp.config(server, opts)
		end
	end,
}

return {}
