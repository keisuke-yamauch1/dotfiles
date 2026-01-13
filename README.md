# dotfiles

macOS用の個人設定ファイル集

## 構成

| ファイル | 説明 |
|---------|------|
| `.zshrc` | zsh設定（PATH、エイリアス、プラグイン） |
| `.zprofile` | シェルプロファイル（Homebrew、Python） |
| `.gitconfig` | Git設定 |
| `.gitignore_global` | グローバルgitignore |
| `.vimrc` | Vim設定 |
| `.config/starship.toml` | Starshipプロンプト設定（Nerd Font対応） |
| `.zsh_scripts/obsidian_helper.sh` | Obsidianデイリーノート用ヘルパー |

## セットアップ

```bash
# リポジトリをクローン
git clone git@github.com:keisuke-yamauch1/dotfiles.git ~/dotfiles

# セットアップスクリプトを実行
~/dotfiles/setup.sh
```

既存ファイルがある場合は `.backup` として退避されます。

## 依存関係

- [Homebrew](https://brew.sh/)
- [Starship](https://starship.rs/) - `brew install starship`
- [Nerd Fonts](https://www.nerdfonts.com/) - Starshipのアイコン表示用
- [anyenv](https://github.com/anyenv/anyenv) - 各種言語バージョン管理
