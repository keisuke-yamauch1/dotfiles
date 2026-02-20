#!/bin/bash

# ===============================================================
#  Obsidian Daily Note Helper `th`
# ===============================================================
#
#  Usage:
#    th "Your thought or memo here"  # Appends the text to today's note
#    th -e                           # Opens today's note in your editor
#
th() {
  # --- 1. 設定項目 (ここを自分の環境に合わせてください) ---

  # Obsidianのヴォルトへの絶対パス
  # 例: "/Users/yourname/Documents/ObsidianVault"
  local VAULT_PATH="~/obsidian"
  ls -la $VAULT_PATH

  # デイリーノートが保存されているフォルダ名 (ヴォルトの直下なら空文字 "")
  # 例: "01_Daily"
  local DAILY_DIR="02_Daily"
  ls -la $VAULT_PATH/$DAILY_DIR

  # 新規デイリーノート作成時に使用するテンプレートのパス
  # 例: "${VAULT_PATH}/99_Templates/DailyNoteTemplate.md"
  local TEMPLATE_PATH="${VAULT_PATH}/101_Templates/daily_note.md"
  ls -la ${VAULT_PATH}/101_Templates

  # --- 2. スクリプト本体 (ここから下は変更不要です) ---

  # 日付と時刻を取得
  local TODAY=$(date '+%Y-%m-%d')
  local NOW=$(date '+%H:%M')

  # デイリーノートのフルパスを組み立て
  local DAILY_NOTE_PATH
  if [ -n "$DAILY_DIR" ]; then
    # DAILY_DIRが設定されている場合
    echo "DAILY_DIRが設定されている場合"
    DAILY_NOTE_PATH="${VAULT_PATH}/${DAILY_DIR}/${TODAY}.md"
  else
    # ヴォルト直下にデイリーノートがある場合
    echo "ヴォルト直下にデイリーノートがある場合"
    DAILY_NOTE_PATH="${VAULT_PATH}/${TODAY}.md"
  fi

  # --- 機能の分岐 ---

  # オプションなし、または引数がない場合のヘルプ表示
  if [ -z "$1" ]; then
    echo "Usage:"
    echo "  th \"Your thought or memo here\""
    echo "  th -e  (Edit today's note)"
    return 1
  fi

  # -e オプション: 今日のノートをエディタで開く
  if [ "$1" = "-e" ]; then
    # ファイルがなければテンプレートから作成
    if [ ! -f "$DAILY_NOTE_PATH" ]; then
      echo "Creating today's note from template: ${DAILY_NOTE_PATH}"
      cp "$TEMPLATE_PATH" "$DAILY_NOTE_PATH"
    fi
    # 環境変数 $EDITOR で指定されたエディタで開く (未設定ならvim)
    ${EDITOR:-vim} "$DAILY_NOTE_PATH"
    return 0
  fi
  echo "DAILY_NOTE_PATH: $DAILY_NOTE_PATH"

  # --- メインの追記処理 ---

  # ファイルがなければテンプレートから作成
  if [ ! -f "$DAILY_NOTE_PATH" ]; then
    echo "Creating today's note from template: ${DAILY_NOTE_PATH}"
    # フォルダがなければ作成
    mkdir -p "$(dirname "$DAILY_NOTE_PATH")"
    cp "$TEMPLATE_PATH" "$DAILY_NOTE_PATH"
  fi

  # 渡された引数すべて($@)をノートに追記
  # 「- HH:MM メモ内容」の形式で書き込む
  echo "- ${NOW} $@" >> "$DAILY_NOTE_PATH"
  echo "Appended to ${TODAY}.md: $@"
}


