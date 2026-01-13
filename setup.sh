#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Setting up dotfiles from: $DOTFILES_DIR"

# シンボリックリンクを作成する関数
link_file() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "  Backup: $dest -> ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi

    ln -sf "$src" "$dest"
    echo "  Linked: $dest -> $src"
}

# .config ディレクトリを作成
mkdir -p ~/.config
mkdir -p ~/.zsh_scripts

echo ""
echo "Creating symlinks..."

# 各dotfileをリンク
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global"
link_file "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
link_file "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
link_file "$DOTFILES_DIR/.zsh_scripts/obsidian_helper.sh" "$HOME/.zsh_scripts/obsidian_helper.sh"

echo ""
echo "Done! Please restart your shell or run: source ~/.zshrc"
