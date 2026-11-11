# opencode-codex-resets

A local OpenCode 2 TUI plugin that shows your **banked Codex rate-limit resets**
in the sidebar, including when each one expires.

```text
Codex resets
2 available                updated just now
19:55 Nov 30                     in 19d
20:37 Dec 1                      in 20d
```

The countdown uses the muted gray while the reset is comfortably far away,
orange within `warnDays` (default 7), and red within `urgentDays` (default 2).

The plugin is read-only: it never redeems a reset. When a reset is about to
expire it offers to open ChatGPT's usage settings, where you can use it.

## How it works

Codex stores banked resets behind the same private ChatGPT backend the official
Codex app uses:

```text
GET https://chatgpt.com/backend-api/wham/rate-limit-reset-credits
```

The plugin reuses the OpenAI OAuth credential already stored by OpenCode
(`context.client.credential.list()`, then `OPENCODE_AUTH_CONTENT`, then the
legacy `auth.json`) and sends it with the same `codex-cli` user agent and
`ChatGPT-Account-Id` header as the official client.

This is the same kind of private backend endpoint that
`opencode-plugin-usage` uses for `wham/usage`. If OpenAI changes it, the section
shows an error instead of breaking the TUI.

## Configuration

Add it to `~/.config/opencode/cli.json`:

```jsonc
{
  "plugins": [
    "opencode-plugin-usage",
    "./tui-plugins/codex-resets"
  ]
}
```

All options are optional:

```jsonc
{
  "plugins": [
    {
      "package": "./tui-plugins/codex-resets",
      "options": {
        "refreshMs": 300000,
        "minRefreshMs": 30000,
        "timeoutMs": 10000,
        "warnDays": 7,
        "urgentDays": 2,
        "hideWhenUnavailable": true,
        "expiryPrompt": {
          "enabled": false,
          "withinMinutes": 15
        }
      }
    }
  ]
}
```

| Option                | Default | Description                                            |
| --------------------- | ------- | ------------------------------------------------------ |
| `refreshMs`           | 300000  | How often to re-fetch reset credits                    |
| `minRefreshMs`        | 30000   | Minimum interval between extra refreshes               |
| `timeoutMs`           | 10000   | Per-request timeout                                    |
| `warnDays`            | 7       | Expiry within this many days is shown in orange        |
| `urgentDays`          | 2       | Expiry within this many days is shown in red           |
| `hideWhenUnavailable` | true    | Hide the section when no OpenAI OAuth credential exists |
| `endpoint`            | —       | Override the reset-credits endpoint                    |

## Expiry prompt

When `expiryPrompt.enabled` is true and a reset is close to expiring, the plugin
asks once whether to open the usage page. The plugin never redeems anything
itself.

```text
Codex reset expiring
A banked Codex reset expires in 14m (20:55 Nov 30).

Open ChatGPT usage settings to use it?

Not Now            Open Settings
```

Accepting opens <https://chatgpt.com/settings/usage> in your browser. Declining
(or pressing Escape) dismisses the reminder for that credit.

## Commands

- `/codex-resets` — show full reset details (title, exact expiry, grant time)
- `Codex resets: open ChatGPT usage settings` — open the usage page manually
- `Codex resets: refresh` — force a refresh from the command palette

## Development

The plugin is plain TypeScript and is loaded directly by OpenCode; there is no
build step. `lib.ts` holds the parser and formatting helpers and has no runtime
dependency on the TUI.
