# ===========================================
# 基本設定
# ===========================================
setopt nonomatch
setopt RM_STAR_SILENT
ZLE_REMOVE_SUFFIX_CHARS=$''

# ===========================================
# PATH設定（一箇所にまとめる）
# ===========================================
typeset -U path PATH
path=(
  $HOME/.cargo/bin
  $HOME/.tiup/bin
  $HOME/.local/bin
  $HOME/.anyenv/bin
  $HOME/.nodenv/bin
  $HOME/.goenv/bin
  $HOME/.deno/bin
  /opt/homebrew/bin(N-/)
  /opt/homebrew/sbin(N-/)
  /usr/local/bin(N-/)
  /usr/local/sbin(N-/)
  /usr/local/go/bin
  /usr/bin
  /usr/sbin
  /bin
  /sbin
  /Library/Apple/usr/bin
  $path
)

# ===========================================
# Homebrew関連（1回のチェックにまとめる）
# ===========================================
if type brew &>/dev/null; then
  BREW_PREFIX=$(brew --prefix)
  FPATH=$BREW_PREFIX/share/zsh-completions:$FPATH
  source $BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  path=($BREW_PREFIX/opt/gnu-sed/libexec/gnubin $path)

  # Python alias
  if [[ -x $BREW_PREFIX/bin/python3.11 ]]; then
    alias python="$BREW_PREFIX/bin/python3.11"
    alias pip="$BREW_PREFIX/bin/pip3.11"
  fi
fi

# Pythonフォールバック
(( $+aliases[python] )) || alias python="/usr/bin/python3"
(( $+aliases[pip] )) || alias pip="/usr/bin/pip3"

# ===========================================
# 環境変数
# ===========================================
export DENO_INSTALL="$HOME/.deno"
export GOENV_ROOT="$HOME/.goenv"
export GOOGLE_CLOUD_PROJECT="empirical-mote-464915-g5"

# ===========================================
# バージョン管理ツール初期化
# ===========================================
eval "$(anyenv init -)"
eval "$(nodenv init -)"
eval "$(goenv init -)"

# ===========================================
# カスタム関数
# ===========================================
tgz() {
  if (( $# < 2 )); then
    echo "Usage: tgz DIST SOURCE..."
    return 1
  fi
  xattr -rc "${@:2}" && \
  env COPYFILE_DISABLE=1 tar zcvf "$1" --exclude=".DS_Store" "${@:2}"
}

# ===========================================
# カスタムスクリプト読み込み
# ===========================================
[[ -f ~/.zsh_scripts/obsidian_helper.sh ]] && source ~/.zsh_scripts/obsidian_helper.sh

# ===========================================
# Starship プロンプト
# ===========================================
eval "$(starship init zsh)"
