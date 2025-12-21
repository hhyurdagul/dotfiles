# 💤 Neovim Configuration

A modern, fast, and lightweight **single-file** Neovim configuration written in Lua.

This setup is built around [lazy.nvim](https://github.com/folke/lazy.nvim) for package management and focuses on providing a clean development environment with robust LSP support, formatting, and autocompletion.

## ✨ Features

- **⚡ Package Management**: [lazy.nvim](https://github.com/folke/lazy.nvim)
- **🎨 Theme**: [Catppuccin](https://github.com/catppuccin/nvim) (Mocha)
- **🧠 LSP**: Native LSP support configured for Lua, Python, Rust, Web (HTML/CSS/TS/JS), Bash, OCaml, and more.
- **🌲 Syntax Highlighting**: [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) with auto-installation for common languages.
- **✨ Completion**: [blink.cmp](https://github.com/saghen/blink.cmp) for fast, fuzzy-search completion.
- **💅 Formatting**: [conform.nvim](https://github.com/stevearc/conform.nvim) for auto-formatting on save.
- **🔍 Fuzzy Finder**: [fzf-lua](https://github.com/ibhagwan/fzf-lua) for files, grep, and LSP symbols.
- **🤖 AI Integration**: [Supermaven](https://github.com/supermaven-inc/supermaven-nvim) for code suggestions.
- **📂 File Explorer**: [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua)
- **🍿 Extras**: `snacks.nvim` for dashboard/notifier, `todo-comments.nvim`, `render-markdown.nvim`.

## 🛠️ Requirements

- **Neovim** >= **0.11.5**
- **Nerd Font**: Required for icons (file explorer, statusline, diagnostics).
- **Git**: For cloning plugins.
- **External Tools**:
  Since this config does *not* use Mason, must be ensured the following language servers and formatters are installed:
  - **LSPs**: `lua-language-server`, `pyrefly` (Python), `rust-analyzer`, `typescript-language-server`, `vscode-html-languageserver`, `bash-language-server`, `tinymist` (Typst), `ocamllsp`.
  - **Formatters**: `stylua`, `black`, `isort`, `rustfmt`, `prettierd`, `shfmt`, `shellcheck`, `ocamlformat`.

## ⌨️ Keymaps

### General
| Key | Action |
| --- | --- |
| `<Space>` | Leader Key |
| `<leader>e` | Toggle File Explorer (NvimTree) |
| `<leader>ff` | Find Files |
| `<leader>fg` | Live Grep |
| `<leader>ft` | Find Todos |
| `ğ` / `ü` | Remapped to `[` / `]` (Turkish keyboard shenanigans) |

### LSP
| Key | Action |
| --- | --- |
| `gd` | Goto Definition |
| `gr` | Goto References |
| `gD` | Goto Declaration |
| `gi` | Goto Implementation |
| `<leader>rn` | Rename Symbol |
| `<leader>ca` | Code Action |
| `<leader>f` | Format File |
| `<leader>th` | Toggle Inlay Hints |
| `<leader>ge` | Open Diagnostics Float |

### AI (Supermaven)
| Key | Action |
| --- | --- |
| `<Alt-a>` | Accept Suggestion |
| `<Alt-w>` | Accept Word |
| `<Alt-]>` | Clear Suggestion |
