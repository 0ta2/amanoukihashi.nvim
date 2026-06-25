# amanoukihashi.nvim

## Claude Code のステータス表示 (任意)

一覧パネルで Claude Code が人間の承認/回答を待っている状態を `⚠` マークで表示できます。
対象プロジェクトの `.claude/settings.json` に以下を追加してください(パスは環境に合わせて変更):

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "/path/to/amanoukihashi.nvim/scripts/claude-hook-status.sh" }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "/path/to/amanoukihashi.nvim/scripts/claude-hook-status.sh" }
        ]
      }
    ]
  }
}
```

amanoukihashi が管理する tmux セッション(`amanoukihashi_` プレフィックス)以外では hook は何もしません。