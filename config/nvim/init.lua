-- =============================================================================
--  Globals
-- =============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- =============================================================================
--  Options
-- =============================================================================
vim.opt.number = true
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "number"
vim.opt.updatetime = 250
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.inccommand = "split"
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.breakindent = true
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.ai = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backupdir = vim.fn.stdpath("cache") .. "/backup"
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.termguicolors = true
vim.opt.compatible = false
vim.opt.syntax = "on"

-- =============================================================================
--  Lazy Bootstrap
-- =============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- =============================================================================
--  Plugins
-- =============================================================================
require("lazy").setup({
	spec = {
		{
			"folke/tokyonight.nvim",
			lazy = false, -- make sure we load this during startup if it is your main colorscheme
			priority = 1000, -- make sure to load this before all the other start plugins
			config = function()
				-- load the colorscheme here
				vim.cmd.colorscheme("tokyonight-night")
			end,
		},
		"neovim/nvim-lspconfig",
		{
			"nvim-treesitter/nvim-treesitter",
			lazy = false,
			build = ":TSUpdate",
			opts = {},
			config = function()
                -- stylua: ignore
                require("nvim-treesitter").install({
                    "bash", "zsh", "make", "cmake", "vim", "gitignore", "dockerfile",
                    "json", "toml", "yaml", "markdown", "markdown_inline", "typst",
                    "html", "css", "javascript", "typescript", "tsx", "astro", "svelte",
                    "lua", "python", "c", "cpp", "rust", "zig", "go", "ocaml",
                })
				vim.api.nvim_create_autocmd("FileType", {
					callback = function(args)
						local bufnr = args.buf
						local has_parser, _ = pcall(vim.treesitter.get_parser, bufnr)

						if has_parser then
							vim.treesitter.start(bufnr)
							vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
						end
					end,
				})
			end,
		},
		{
			"stevearc/conform.nvim",
			opts = {
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "black", "isort" },
					rust = { "rustfmt", lsp_format = "fallback" },
					javascript = { "prettierd", "prettier", stop_after_first = true },
					typescript = { "prettierd", "prettier", stop_after_first = true },
					json = { "prettierd", "prettier", stop_after_first = true },
					bash = { "shfmt", "shellcheck" },
					sh = { "shfmt", "shellcheck" },
					zsh = { "shfmt", "shellcheck" },
					ocaml = { "ocamlformat" },
				},
			},
		},
		{
			"saghen/blink.cmp",
			dependencies = { "rafamadriz/friendly-snippets" },
			version = "1.*",
			opts = {
				keymap = {
					preset = "enter",
					["<Up>"] = { "select_prev", "fallback" },
					["<Down>"] = { "select_next", "fallback" },
					["<Tab>"] = { "select_next", "fallback" },
					["<S-Tab>"] = { "select_prev", "fallback" },
				},

				appearance = {
					nerd_font_variant = "mono",
				},
				completion = { documentation = { auto_show = true } },
				signature = { enabled = true },
				sources = {
					default = { "lsp", "path", "snippets", "buffer" },
				},
				fuzzy = { implementation = "prefer_rust_with_warning" },
			},
			opts_extend = { "sources.default" },
		},
		{ "saghen/blink.pairs", version = "*", dependencies = "saghen/blink.download", opts = {} },
		{
			"ibhagwan/fzf-lua",
			dependencies = { "nvim-tree/nvim-web-devicons" },
			config = function()
				require("fzf-lua").setup({})

				local map = function(keys, func, desc)
					vim.keymap.set("n", keys, func, { desc = "Fzf: " .. desc })
				end

				map("<leader>ff", require("fzf-lua").files, "Opens File picker")
				map("<leader>fg", require("fzf-lua").live_grep, "Opens Live grep picker")
				map("<leader>fd", require("fzf-lua").diagnostics_document, "Opens Live grep picker")
				map("<leader>ft", "<cmd>TodoFzfLua<CR>", "Open Todos")
				map("<leader>ds", require("fzf-lua").lsp_document_symbols, "Open Document Symbols")
				map("<leader>ws", require("fzf-lua").lsp_live_workspace_symbols, "Open Workspace Symbols")
			end,
		},
		{
			"nvim-tree/nvim-tree.lua",
			version = "*",
			lazy = false,
			dependencies = {
				"nvim-tree/nvim-web-devicons",
			},
			opts = {},
			config = function()
				require("nvim-tree").setup({})
				vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { noremap = true })
			end,
		},
		{
			"nvim-lualine/lualine.nvim",
			opts = {},
		},
		{
			"supermaven-inc/supermaven-nvim",
			opts = {
				keymaps = {
					accept_suggestion = "<A-a>",
					clear_suggestion = "<A-]>",
					accept_word = "<A-w>",
				},
			},
		},
		{
			"folke/snacks.nvim",
			priority = 1000,
			lazy = false,
			opts = {
				dashboard = { enabled = true },
				indent = { enabled = true },
				input = { enabled = true },
				notifier = { enabled = true },
				scroll = { enabled = true },
				statuscolumn = { enabled = true },
			},
		},
		{
			"folke/todo-comments.nvim",
			opts = {},
		},
		{
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {},
		},
	},
	checker = { enabled = true },
})

-- =============================================================================
--  General Keymaps
-- =============================================================================
vim.keymap.set("n", "ğ", "[", { remap = true })
vim.keymap.set("n", "ü", "]", { remap = true })
vim.keymap.set("v", "p", '"_dP', { remap = false })
vim.keymap.set("i", "<S-Tab>", "<C-d>", { noremap = true })

-- -- Normal Mode: Start selection
-- vim.keymap.set("n", ",", function()
--   vim.lsp.buf.selection_range("outer")
-- end, { desc = "LSP: Init selection" })
--
-- -- Visual Mode: Expand (Direction = 1)
-- vim.keymap.set("x", ",", function()
--   vim.lsp.buf.selection_range("outer")
-- end, { desc = "LSP: Expand selection" })
--
-- -- Visual Mode: Shrink (Direction = -1)
-- vim.keymap.set("x", "<BS>", function()
--   vim.lsp.buf.selection_range("inner")
-- end, { desc = "LSP: Shrink selection" })

-- =============================================================================
--  General Autocmds
-- =============================================================================
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
	desc = "Highlight on yank",
	group = vim.api.nvim_create_augroup("highlight-on-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- =============================================================================
--  LSP & Diagnostics
-- =============================================================================
vim.diagnostic.config({
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = vim.diagnostic.severity.ERROR },
	signs = vim.g.have_nerd_font and {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚 ",
			[vim.diagnostic.severity.WARN] = "󰀪 ",
			[vim.diagnostic.severity.INFO] = "󰋽 ",
			[vim.diagnostic.severity.HINT] = "󰌶 ",
		},
	} or {},
	virtual_text = {
		source = "if_many",
		spacing = 2,
		format = function(diagnostic)
			local diagnostic_message = {
				[vim.diagnostic.severity.ERROR] = diagnostic.message,
				[vim.diagnostic.severity.WARN] = diagnostic.message,
				[vim.diagnostic.severity.INFO] = diagnostic.message,
				[vim.diagnostic.severity.HINT] = diagnostic.message,
			}
			return diagnostic_message[diagnostic.severity]
		end,
	},
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc, mode)
			mode = mode or "n"
			vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end
		map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
		map("<leader>ca", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
		map("<leader>gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
		map("<leader>gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
		map("<leader>gr", vim.lsp.buf.references, "[G]oto [R]eferences")
		map("<leader>gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
		map("<leader>f", function()
			require("conform").format({ lsp_format = "fallback", async = true })
		end, "[F]ormat")
		map("<leader>ge", vim.diagnostic.open_float, "Open Diagnostics")
		map("<leader>n", vim.diagnostic.goto_next, "Go to Next Diagnostics")
		map("<leader>p", vim.diagnostic.goto_prev, "Go to Previous Diagnostics")

		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if
			client
			and client.supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
		then
			local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.document_highlight,
			})

			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.clear_references,
			})

			vim.api.nvim_create_autocmd("LspDetach", {
				group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
				callback = function(event2)
					vim.lsp.buf.clear_references()
					vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
				end,
			})
		end
		map("<leader>th", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
		end, "[T]oggle Inlay [H]ints")
	end,
})

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
        -- stylua: ignore
		vim.lsp.enable({
			"lua_ls", "ty", "html", "tinymist", "jsonls", "clangd",
            "rust_analyzer", "bashls", "astro", "ts_ls", "ocamllsp",
            "zls"
        })
	end,
})

vim.lsp.config("ts_ls", {
	init_options = {
		typescript = {
			tsdk = "~/.local/share/mise/installs/node/22.20.0/lib/node_modules/typescript/lib",
		},
	},
})
