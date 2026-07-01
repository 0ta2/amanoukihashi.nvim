#!/bin/bash
# Claude Code の hook から呼ばれ、tmux pane-local option に状態を書き込む。
# amanoukihashi 管理外の tmux セッションでは何もしない。
set -euo pipefail

input=$(cat)

if [ -z "${TMUX:-}" ]; then
  exit 0
fi

session=$(tmux display-message -p '#{session_name}')
# "amanoukihashi_" は lua/amanoukihashi/tmux.lua の PREFIX 定数と同じ値。
# 変更する場合は両方を揃えること。
case "$session" in
  amanoukihashi_*) ;;
  *) exit 0 ;;
esac

# session_id を hook ペイロードから抽出して pane option に保存
session_id=$(printf '%s' "$input" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true)
if [ -n "$session_id" ]; then
  tmux set-option -p @ama_claude_session_id "$session_id"
fi

if printf '%s' "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"Notification"'; then
  tmux set-option -p @ama_status needs_attention
elif printf '%s' "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"UserPromptSubmit"'; then
  tmux set-option -p @ama_status ""
fi
