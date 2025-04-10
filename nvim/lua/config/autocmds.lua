vim.api.nvim_create_autocmd({ "TextYankPost" }, {
	desc = "Highlight on yank",
	group = vim.api.nvim_create_augroup("highlight-on-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function(args)
		require("conform").format({ bufnr = args.buf })
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp_attach_disable_ruff_hover", { clear = true }),
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client == nil then
			return
		end
		if client.name == "ruff" then
			-- Disable hover in favor of Pyright
			client.server_capabilities.hoverProvider = false
		end
	end,
	desc = "LSP: Disable hover capability from Ruff",
})

-- Tab size for files
vim.cmd("autocmd BufRead,BufEnter *.astro set filetype=astro")
vim.cmd("autocmd FileType javascript setlocal shiftwidth=2 softtabstop=2 expandtab")
vim.cmd("autocmd FileType typescript setlocal shiftwidth=2 softtabstop=2 expandtab")
vim.cmd("autocmd FileType javascriptreact setlocal shiftwidth=2 softtabstop=2 expandtab")
vim.cmd("autocmd FileType typescriptreact setlocal shiftwidth=2 softtabstop=2 expandtab")
vim.cmd("autocmd FileType jsx setlocal shiftwidth=2 softtabstop=2 expandtab")
vim.cmd("autocmd FileType tsx setlocal shiftwidth=2 softtabstop=2 expandtab")
vim.cmd("autocmd FileType json setlocal shiftwidth=2 softtabstop=2 expandtab")
vim.cmd("autocmd FileType html setlocal shiftwidth=2 softtabstop=2 expandtab")
vim.cmd("autocmd FileType css setlocal shiftwidth=2 softtabstop=2 expandtab")
vim.cmd("autocmd FileType nix setlocal shiftwidth=2 softtabstop=2 expandtab")
vim.cmd("autocmd FileType * set formatoptions-=cro")
