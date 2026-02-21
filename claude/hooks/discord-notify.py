#!/usr/bin/env python3
"""Claude Code → Discord notification via webhook."""

import json
import os
import sys
import urllib.request

def load_env(path: str) -> None:
    """シンプルな.envファイル読み込み。KEY=VALUE形式を環境変数にセットする。"""
    if not os.path.isfile(path):
        return
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, _, value = line.partition("=")
                os.environ.setdefault(key.strip(), value.strip())


load_env(os.path.expanduser("~/.claude/.env"))

WEBHOOK_URL = os.environ.get("CLAUDE_DISCORD_WEBHOOK_URL", "")
if not WEBHOOK_URL:
    sys.exit(0)

data = json.load(sys.stdin)
event = data.get("hook_event_name", "Unknown")
cwd = data.get("cwd", "")
session_id = data.get("session_id", "")[:8]

title = ""
message = ""
color = 5814783


def extract_from_transcript(path: str, role: str, limit: int = 200) -> str:
    """transcript_pathから指定ロールの最後のメッセージを抽出する。"""
    if not path or not os.path.isfile(path):
        return ""
    with open(path, "r") as f:
        lines = f.readlines()
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        if entry.get("type") != role:
            continue
        content = entry.get("message", {}).get("content", "")
        # contentは文字列の場合とブロック配列の場合がある
        if isinstance(content, str):
            text = content
        elif isinstance(content, list):
            texts = []
            for c in content:
                if isinstance(c, str):
                    texts.append(c)
                elif isinstance(c, dict) and c.get("type") == "text" and c.get("text"):
                    texts.append(c["text"])
            text = texts[0] if texts else ""
        else:
            continue
        if text:
            if len(text) > limit:
                return text[:limit] + "..."
            return text
    return ""


# --- Stop: 返信完了 ---
if event == "Stop":
    if data.get("stop_hook_active"):
        sys.exit(0)

    title = "✅ 返信完了"
    color = 3066993  # 緑

    transcript = data.get("transcript_path", "")
    user_msg = extract_from_transcript(transcript, "user", 100)
    assistant_msg = extract_from_transcript(transcript, "assistant", 300)

    parts = []
    if user_msg:
        parts.append(f"> {user_msg}")
    if assistant_msg:
        parts.append(assistant_msg)
    message = "\n\n".join(parts) if parts else "Claudeの返信が完了しました。"

# --- Notification: 権限確認・アイドル ---
elif event == "Notification":
    ntype = data.get("notification_type", "unknown")
    nmsg = data.get("message", "")
    if ntype == "permission_prompt":
        title = "⚠️ 確認待ち"
        color = 15105570  # オレンジ
        message = nmsg or "権限の確認が必要です。"
    elif ntype == "idle_prompt":
        title = "💤 入力待ち"
        color = 9807270  # グレー
        message = nmsg or "Claudeが入力を待っています。"
    else:
        title = "🔔 通知"
        color = 3447003  # 青
        message = nmsg or "通知があります。"

if not title:
    sys.exit(0)

# フッターにcwdとセッションIDを表示
footer_parts = []
if cwd:
    footer_parts.append(f"📁 {cwd}")
if session_id:
    footer_parts.append(f"🔑 {session_id}")
footer = "  |  ".join(footer_parts)

# Discord Webhookに送信
payload = json.dumps({
    "embeds": [{
        "title": title,
        "description": message,
        "color": color,
        **({"footer": {"text": footer}} if footer else {}),
    }]
}).encode()

req = urllib.request.Request(
    WEBHOOK_URL,
    data=payload,
    headers={
        "Content-Type": "application/json",
        "User-Agent": "Claude-Code-Hook/1.0",
    },
    method="POST",
)
try:
    urllib.request.urlopen(req, timeout=10)
except Exception:
    pass
