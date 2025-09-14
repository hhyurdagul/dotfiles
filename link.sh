#!/bin/bash
#
# A script to symlink dotfiles from this repository to the correct locations.

# --- Shell Setup ---
# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Pipes fail on the first command that fails, not the last.
set -o pipefail

# --- Path Setup ---
# Change to the directory where the script is located to make all paths relative.
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Define source and destination directories
SOURCE_HOME_DIR="$SCRIPT_DIR/home"
SOURCE_CONFIG_DIR="$SCRIPT_DIR/config"
DEST_CONFIG_DIR="$HOME/.config"

# --- Helper Functions ---
# Simple logging functions for clearer output
info() {
    echo "[INFO] $1"
}

success() {
    echo "✅ [SUCCESS] $1"
}

warn() {
    echo "⚠️  [WARN] $1"
}


# --- Link Home Directory Files ---
info "Linking home directory files..."
# Ensure the source directory exists before proceeding
if [ ! -d "$SOURCE_HOME_DIR" ]; then
    warn "Source home directory not found: $SOURCE_HOME_DIR. Skipping."
else
    # Loop through all files (including hidden ones) in the source directory.
    # This approach correctly handles filenames with spaces.
    find "$SOURCE_HOME_DIR" -maxdepth 1 -mindepth 1 | while read -r source_path; do
        filename=$(basename "$source_path")
        dest_path="$HOME/$filename"
        info "  Linking '$filename' to $HOME"
        # -s: symbolic link, -f: force (overwrite destination if it exists)
        ln -sf "$source_path" "$dest_path"
    done
fi
success "Home directory files linked."

# ---

## Link Configuration Files
info "Linking .config directory files..."

# Ensure the destination .config directory exists
mkdir -p "$DEST_CONFIG_DIR"

# --- Configuration Setup ---
# Define configurations for different platforms
COMMON_CONFIGS=("nvim" "wezterm", "kitty")
LINUX_ONLY_CONFIGS=("hypr" "waybar", "wofi")
MAC_ONLY_CONFIGS=("yabai" "karabiner")

# Determine which configs to link based on the OS
TARGET_CONFIGS=()
OS_NAME=$(uname -s)

case "$OS_NAME" in
    Linux)
        info "Detected OS: Linux"
        TARGET_CONFIGS=("${COMMON_CONFIGS[@]}" "${LINUX_ONLY_CONFIGS[@]}")
        ;;
    Darwin)
        info "Detected OS: macOS"
        TARGET_CONFIGS=("${COMMON_CONFIGS[@]}" "${MAC_ONLY_CONFIGS[@]}")
        ;;
    *)
        warn "Unsupported OS '$OS_NAME'. Only linking common configs."
        TARGET_CONFIGS=("${COMMON_CONFIGS[@]}")
        ;;
esac

info "Will link the following configs: ${TARGET_CONFIGS[*]}"

# Loop through the target configs and create symlinks
for config in "${TARGET_CONFIGS[@]}"; do
    source_path="$SOURCE_CONFIG_DIR/$config"
    dest_path="$DEST_CONFIG_DIR/$config"

    # Check if the source config directory actually exists before linking
    if [ -e "$source_path" ]; then
        info "  Linking '$config' to $DEST_CONFIG_DIR"
        ln -sf "$source_path" "$dest_path"
    else
        warn "Source config not found, skipping: $source_path"
    fi
done

success "Configuration files linked."
