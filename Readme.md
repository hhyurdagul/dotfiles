# HHYurdagul's Dotfiles

This repository contains my personal dotfiles for various applications and environments. The setup is managed by a simple shell script that creates symlinks for configuration files, with support for both macOS and Linux.

## Philosophy

These dotfiles are designed to create a consistent and efficient development environment across both macOS and Linux. The focus is on a keyboard-driven workflow, with a tiling window manager and a highly customized Neovim setup at the core.

## What's Included

### Core Components

-   **Window Manager**:
    -   **macOS**: [Yabai](https://github.com/koekeishiya/yabai) - A tiling window manager for macOS.
    -   **Linux**: [Hyprland](https://hyprland.org/) - A dynamic tiling Wayland compositor.
-   **Terminal**: [WezTerm](https://wezfurlong.org/wezterm/) - A GPU-accelerated cross-platform terminal emulator.
-   **Shell**: [Zsh](https://www.zsh.org/) with [Powerlevel10k](https://github.com/romkatv/powerlevel10k) for a fast and feature-rich prompt, and [Zinit](https://github.com/zdharma-continuum/zinit) for plugin management.
-   **Editor**: [Neovim](https://neovim.io/) configured with [Lazy.nvim](https://github.com/folke/lazy.nvim) for plugin management. The setup includes:
    -   **Theme**: [Catppuccin](https://github.com/catppuccin/nvim)
    -   **Completion**: [blink.cmp](https://github.com/saghen/blink.cmp) and [Codeium](https://codeium.com/)
    -   **LSP**: [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) for language server support.
    -   **Formatting**: [conform.nvim](https://github.com/stevearc/conform.nvim) for code formatting.
    -   **Fuzzy Finder**: [fzf-lua](https://github.com/ibhagwan/fzf-lua) for fast file and text searching.
    -   **File Explorer**: [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua)
    -   **Note Taking**: [Neorg](https://github.com/nvim-neorg/neorg)
-   **Keyboard Customization (macOS)**: [Karabiner-Elements](https://karabiner-elements.pqrs.org/) for complex keyboard modifications.
-   **Status Bar (Linux)**: [Waybar](https://github.com/Alexays/Waybar) - A highly customizable Wayland bar for Sway and Wlroots based compositors.

### Other Tools

-   **[Tmux](https://github.com/tmux/tmux)**: A terminal multiplexer.
-   **[Git](https://git-scm.com/)**: Version control.

## Prerequisites

-   A Unix-like operating system (macOS or Linux).
-   All the applications you want to use (e.g., Neovim, WezTerm, Yabai) should be installed.
-   `git` should be installed to clone the repository.

## Installation

The `link.sh` script will symlink the files and directories from this repository to the correct locations in your home directory and `.config` directory.

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/your-username/dotfiles.git ~/.config/dotfiles
    ```

2.  **Run the link script:**

    ```bash
    cd ~/.config/dotfiles
    ./link.sh
    ```

The script will automatically detect your operating system and link the appropriate configuration files.

## Keybindings

This setup relies heavily on keyboard shortcuts. Here are some of the most important ones:

### Yabai (macOS)

-   `cmd - h/j/k/l`: Focus window left/down/up/right.
-   `cmd - shift - h/j/k/l`: Move window left/down/up/right.

### Hyprland (Linux)

-   `Super - h/j/k/l`: Focus window left/down/up/right.
-   `Super - Shift - h/j/k/l`: Move window left/down/up/right.
-   `Super - Return`: Open terminal.
-   `Super - Q`: Kill active window.
-   `Super - R`: Open application launcher (wofi).

### Karabiner-Elements (macOS)

-   `left_command + h/j/k/l`: Remapped to arrow keys. (For keyboards without arrow keys.)

## Repository Structure

-   `config/`: Contains configuration files for applications that follow the XDG Base Directory Specification.
-   `home/`: Contains configuration files that are located in the home directory.
-   `link.sh`: The script that creates the symlinks.
-   `unused/`: Contains configurations that are not currently in use, including:
    -   [Aerospace](https://github.com/nikitabobko/AeroSpace): An i3-like tiling window manager for macOS.
    -   [Alacritty](https://alacritty.org/): A cross-platform, OpenGL terminal emulator.
    -   [Home Manager](https://github.com/nix-community/home-manager): A tool to manage a user environment using the Nix package manager.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
