#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Setting up dotfiles from: $DOTFILES_DIR"

# フォントのインストール確認
echo ""
echo "Checking font installation..."
if ! brew list --cask font-hack-nerd-font &>/dev/null; then
    echo "  Installing Hack Nerd Font..."
    brew install --cask font-hack-nerd-font
    echo "  Font installed successfully!"
else
    echo "  Hack Nerd Font is already installed."
fi

# ファイルをコピーする関数
copy_file() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "  Backup: $dest -> ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi

    cp "$src" "$dest"
    echo "  Copied: $src -> $dest"
}

# コピー先ディレクトリを作成
mkdir -p ~/.config
mkdir -p ~/.zsh_scripts
mkdir -p ~/.config/ghostty
mkdir -p ~/.config/deck
mkdir -p ~/.config/laminate
mkdir -p ~/.claude
mkdir -p ~/.claude/hooks

echo ""
echo "Copying dotfiles..."

# 各dotfileをコピー
copy_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
copy_file "$DOTFILES_DIR/zsh/.zprofile" "$HOME/.zprofile"
copy_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
copy_file "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"
copy_file "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"
copy_file "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
copy_file "$DOTFILES_DIR/zsh_scripts/obsidian_helper.sh" "$HOME/.zsh_scripts/obsidian_helper.sh"
copy_file "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"
copy_file "$DOTFILES_DIR/deck/config.yml" "$HOME/.config/deck/config.yml"
copy_file "$DOTFILES_DIR/laminate/config.yaml" "$HOME/.config/laminate/config.yaml"
copy_file "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
copy_file "$DOTFILES_DIR/claude/hooks/discord-notify.py" "$HOME/.claude/hooks/discord-notify.py"

# .envは既存がなければsampleからコピー（既存の設定を上書きしない）
if [ ! -e "$HOME/.claude/.env" ]; then
    cp "$DOTFILES_DIR/claude/.env.sample" "$HOME/.claude/.env"
    echo "  Created: $HOME/.claude/.env (from .env.sample)"
    echo "  ⚠ ~/.claude/.env を編集して実際のWebhook URLを設定してください"
else
    echo "  Skipped: $HOME/.claude/.env (already exists)"
fi

echo ""
echo "Done! Please restart your shell or run: source ~/.zshrc"
