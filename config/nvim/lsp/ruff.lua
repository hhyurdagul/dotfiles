---@brief
---
--- https://github.com/astral-sh/ruff
---
--- A Language Server Protocol implementation for Ruff, an extremely fast Python linter and code formatter, written in Rust. It can be installed via `pip`.
---
--- Refer to the [documentation](https://docs.astral.sh/ruff/editors/) for more details.

return {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git', 'requirements.txt' },
  settings = {},
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspRuffOrganizeImports', function()
      client:exec_cmd({
        command = 'ruff.organizeImports',
        arguments = { vim.uri_from_bufnr(bufnr) },
      })
    end, {
      desc = 'Organize Imports',
    })
  end
}
