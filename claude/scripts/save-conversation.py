#!/usr/bin/env python3
"""
Claude Code Hook: 会話をObsidian vaultのconversations/に自動保存
SessionStart / Stop / SessionEnd で呼び出す

Usage:
  python3 save-conversation.py --event start
  python3 save-conversation.py --event stop
  python3 save-conversation.py --event end
"""

import json
import os
import re
import sys
import time
import argparse
from datetime import datetime
from pathlib import Path

VAULT = Path("/Users/keisuke/Library/Mobile Documents/iCloud~md~obsidian/Documents/claude-obsidian")
CONVERSATIONS_DIR = VAULT / ".raw" / "conversations"
STATE_FILE = Path.home() / ".claude" / "obsidian-hook-state.json"

# フィルタするノイズパターン（system tags）
NOISE_TAGS = [
    "system-reminder",
    "local-command-caveat",
    "bash-input", "bash-stdout", "bash-stderr",
    "command-name", "command-message", "command-args",
]

def build_noise_patterns():
    patterns = []
    for tag in NOISE_TAGS:
        patterns.append(re.compile(f"<{tag}>.*?</{tag}>", re.DOTALL))
    # function_calls blocks
    fc_open = "<" + "function_calls>"
    fc_close = "</" + "function_calls>"
    patterns.append(re.compile(re.escape(fc_open) + ".*?" + re.escape(fc_close), re.DOTALL))
    return patterns

NOISE_PATTERNS = build_noise_patterns()


def get_project_name() -> str:
    cwd = Path(os.getcwd()).resolve()
    vault = VAULT.resolve()
    if cwd == vault:
        return "claude-obsidian"
    return cwd.name


def get_transcript_path(session_id: str) -> Path:
    cwd = os.getcwd()
    sanitized = re.sub(r"[^a-zA-Z0-9]", "-", cwd)
    return Path.home() / ".claude" / "projects" / sanitized / f"{session_id}.jsonl"


def load_state() -> dict:
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text())
        except Exception:
            pass
    return {}


def save_state(state: dict):
    STATE_FILE.write_text(json.dumps(state, indent=2))


def clean_text(text: str) -> str:
    for pattern in NOISE_PATTERNS:
        text = pattern.sub("", text)
    return text.strip()


def get_text_from_content(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                parts.append(block.get("text", ""))
        return "\n".join(parts)
    return ""


def read_new_messages(transcript_path: Path, from_line: int) -> tuple[list[dict], int]:
    messages = []
    line_count = 0
    try:
        with open(transcript_path, encoding="utf-8") as f:
            lines = f.readlines()
        line_count = len(lines)
        for line in lines[from_line:]:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
                msg_type = entry.get("type")
                if msg_type not in ("user", "assistant"):
                    continue
                message = entry.get("message", {})
                content = message.get("content", "")
                text = clean_text(get_text_from_content(content))
                if not text:
                    continue
                ts = entry.get("timestamp", "")
                if ts:
                    try:
                        dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                        time_str = dt.strftime("%H:%M:%S")
                    except Exception:
                        time_str = ""
                else:
                    time_str = ""
                messages.append({
                    "role": msg_type,
                    "text": text,
                    "time": time_str,
                })
            except Exception:
                continue
    except Exception:
        pass
    return messages, line_count


def format_messages(messages: list[dict]) -> str:
    lines = []
    for msg in messages:
        role = "User" if msg["role"] == "user" else "Claude"
        time_prefix = f"{msg['time']} " if msg["time"] else ""
        lines.append(f"### {time_prefix}{role}\n\n{msg['text']}\n")
    return "\n".join(lines)


def on_session_start(session_id: str, hook_input: dict):
    project = get_project_name()
    transcript_path = get_transcript_path(session_id)
    now = datetime.now()
    date_str = now.strftime("%Y-%m-%d")
    time_str = now.strftime("%H%M%S")

    CONVERSATIONS_DIR.mkdir(exist_ok=True)
    out_file = CONVERSATIONS_DIR / f"{date_str}-{time_str}-{project}-{session_id[:8]}.md"

    cwd = str(Path(os.getcwd()).resolve())
    frontmatter = f"""---
type: conversation
project: {project}
cwd: {cwd}
session_id: {session_id}
time_start: {now.isoformat()}
time_end: ""
created: {date_str}
---

"""
    out_file.write_text(frontmatter, encoding="utf-8")

    state = load_state()
    state[session_id] = {
        "transcript_path": str(transcript_path),
        "output_file": str(out_file),
        "last_line": 0,
    }
    save_state(state)


def on_stop(session_id: str, hook_input: dict):
    time.sleep(1)  # transcript書き込み完了を待つ

    state = load_state()
    if session_id not in state:
        # SessionStartが無かった場合のフォールバック
        on_session_start(session_id, hook_input)
        state = load_state()

    session_state = state[session_id]
    transcript_path = Path(session_state["transcript_path"])
    out_file = Path(session_state["output_file"])
    last_line = session_state.get("last_line", 0)

    messages, new_line_count = read_new_messages(transcript_path, last_line)
    if messages:
        with open(out_file, "a", encoding="utf-8") as f:
            f.write(format_messages(messages) + "\n")

    session_state["last_line"] = new_line_count
    save_state(state)


def on_session_end(session_id: str, hook_input: dict):
    on_stop(session_id, hook_input)

    state = load_state()
    if session_id not in state:
        return

    session_state = state[session_id]
    out_file = Path(session_state["output_file"])

    # time_end を更新
    now = datetime.now().isoformat()
    if out_file.exists():
        content = out_file.read_text(encoding="utf-8")
        content = content.replace('time_end: ""', f"time_end: {now}", 1)
        out_file.write_text(content, encoding="utf-8")

    # 状態をクリーンアップ
    del state[session_id]
    save_state(state)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--event", choices=["start", "stop", "end"], required=True)
    args = parser.parse_args()

    hook_input = {}
    try:
        raw = sys.stdin.read()
        if raw.strip():
            hook_input = json.loads(raw)
    except Exception:
        pass

    session_id = hook_input.get("session_id", "unknown")

    if args.event == "start":
        on_session_start(session_id, hook_input)
    elif args.event == "stop":
        on_stop(session_id, hook_input)
    elif args.event == "end":
        on_session_end(session_id, hook_input)


if __name__ == "__main__":
    main()