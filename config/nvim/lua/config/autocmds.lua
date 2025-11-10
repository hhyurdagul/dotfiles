vim.api.nvim_create_autocmd({ "TextYankPost" }, {
	desc = "Highlight on yank",
	group = vim.api.nvim_create_augroup("highlight-on-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- vim.api.nvim_create_autocmd("BufWritePre", {
-- 	pattern = "*",
-- 	callback = function(args)
-- 		require("conform").format({ bufnr = args.buf })
-- 	end,
-- })

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

-- AMP

-- Send a quick message to the agent
vim.api.nvim_create_user_command("AmpSend", function(opts)
	local message = opts.args
	if message == "" then
		print("Please provide a message to send")
		return
	end

	local amp_message = require("amp.message")
	amp_message.send_message(message)
end, {
	nargs = "*",
	desc = "Send a message to Amp",
})

-- Send entire buffer contents
vim.api.nvim_create_user_command("AmpSendBuffer", function(opts)
	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local content = table.concat(lines, "\n")

	local amp_message = require("amp.message")
	amp_message.send_message(content)
end, {
	nargs = "?",
	desc = "Send current buffer contents to Amp",
})

-- Add selected text directly to prompt
vim.api.nvim_create_user_command("AmpPromptSelection", function(opts)
	local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
	local text = table.concat(lines, "\n")

	local amp_message = require("amp.message")
	amp_message.send_to_prompt(text)
end, {
	range = true,
	desc = "Add selected text to Amp prompt",
})

-- Add file+selection reference to prompt
vim.api.nvim_create_user_command("AmpPromptRef", function(opts)
	local bufname = vim.api.nvim_buf_get_name(0)
	if bufname == "" then
		print("Current buffer has no filename")
		return
	end

	local relative_path = vim.fn.fnamemodify(bufname, ":.")
	local ref = "@" .. relative_path
	if opts.line1 ~= opts.line2 then
		ref = ref .. "#L" .. opts.line1 .. "-" .. opts.line2
	elseif opts.line1 > 1 then
		ref = ref .. "#L" .. opts.line1
	end

	local amp_message = require("amp.message")
	amp_message.send_to_prompt(ref)
end, {
	range = true,
	desc = "Add file reference (with selection) to Amp prompt",
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
vim.cmd("autocmd FileType lua setlocal shiftwidth=2 softtabstop=2 expandtab")
vim.cmd("autocmd FileType astro setlocal shiftwidth=2 softtabstop=2 expandtab")
vim.cmd("autocmd FileType * set formatoptions-=cro")
