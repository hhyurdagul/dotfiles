local lspconfig = require("lspconfig")
require("nvim-lsp-installer").setup({
    automatic_installation = true, -- automatically detect which servers to install (based on which servers are set up via lspconfig)
    ui = {
        icons = {
            server_installed = "✓",
            server_pending = "➜",
            server_uninstalled = "✗"
        }
    }
})


local buf_set_keymap = function(bufnr, mode, lhs, rhs, opts)
    vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts or {
        noremap = true,
        silent = true,
    })
end

local on_attach = function(client, bufnr)
    require "lsp_signature".on_attach()

    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap(bufnr, 'n', '<space>gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
    buf_set_keymap(bufnr, 'n', '<space>gr', '<cmd>lua vim.lsp.buf.references()<CR>')
    buf_set_keymap(bufnr, 'n', '<space>ge', '<cmd>lua vim.diagnostic.open_float()<CR>')
    buf_set_keymap(bufnr, 'n', '<space>gp', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
    buf_set_keymap(bufnr, 'n', '<space>gn', '<cmd>lua vim.diagnostic.goto_next()<CR>')
    buf_set_keymap(bufnr, 'n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>')
    buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
    buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
    buf_set_keymap(bufnr, 'n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>')
    buf_set_keymap(bufnr, 'n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>')
    buf_set_keymap(bufnr, 'n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>')
    buf_set_keymap(bufnr, 'n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
    buf_set_keymap(bufnr, 'n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>')

    if client.resolved_capabilities.document_formatting then
        vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()")
    end

end
-- Register a handler that will be called for each installed server when it's ready (i.e. when installation is finished
-- or if the server is already installed).

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
local opts = {
    on_attach = on_attach,
    flags = {
        debounce_text_changes = 150,
    },
    capabilities = capabilities,
}

local tsserver_on_attach = function(client, bufnr)
    client.resolved_capabilities.document_formatting = true
    client.resolved_capabilities.document_range_formatting = true
    local ts_utils = require("nvim-lsp-ts-utils")
    ts_utils.setup({})
    ts_utils.setup_client(client)
    buf_set_keymap(bufnr, "n", "gs", ":TSLspOrganize<CR>")
    buf_set_keymap(bufnr, "n", "gi", ":TSLspRenameFile<CR>")
    buf_set_keymap(bufnr, "n", "go", ":TSLspImportAll<CR>")
    on_attach(client, bufnr)
end

lspconfig.sumneko_lua.setup { on_attach = on_attach, capabilities = capabilities }
lspconfig.clangd.setup { on_attach = on_attach, capabilities = capabilities }
lspconfig.rust_analyzer.setup { on_attach = on_attach, capabilities = capabilities }
lspconfig.pyright.setup { on_attach = on_attach, capabilities = capabilities }
lspconfig.cssls.setup { on_attach = on_attach, capabilities = capabilities }
lspconfig.tailwindcss.setup { on_attach = on_attach, capabilities = capabilities }
lspconfig.svelte.setup { on_attach = on_attach, capabilities = capabilities }
lspconfig.texlab.setup { on_attach = on_attach, capabilities = capabilities }
lspconfig.emmet_ls.setup { on_attach = on_attach, capabilities = capabilities,
    filetypes = { 'html', 'typescriptreact', 'javascriptreact', 'css', 'sass', 'scss', 'less' } }
lspconfig.denols.setup { on_attach = on_attach, capabilities = capabilities,
    root_dir = lspconfig.util.root_pattern("deno.json"), single_file_support = false }
lspconfig.tsserver.setup { on_attach = tsserver_on_attach, capabilities = capabilities,
    root_dir = lspconfig.util.root_pattern('package.json') }

lspconfig.julials.setup { on_attach = on_attach, capabilities = capabilities }
