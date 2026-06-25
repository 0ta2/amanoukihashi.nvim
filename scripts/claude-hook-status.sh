#!/bin/bash
# Claude Code の Notification/UserPromptSubmit hook から呼ばれ、
# tmux pane-local option @ama_status に状態を書き込む。
# amanoukihashi 管理外の tmux セッションでは何もしない。
set -euo pipefail

input=$(cat)
if printf '%s' "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"Notification"'; then
  event="Notification"
elif printf '%s' "$input" | grep -q '"hook_event_name"[[:space:]]*:[[:space:]]*"UserPromptSubmit"'; then
  event="UserPromptSubmit"
else
  exit 0
fi

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

case "$event" in
  Notification)
    tmux set-option -p @ama_status needs_attention
    ;;
  UserPromptSubmit)
    tmux set-option -p @ama_status ""
    ;;
esac
