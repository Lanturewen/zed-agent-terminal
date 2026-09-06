# Zed Agent Terminal Integration

> Dynamic brand icons and real-time activity indicators for interactive CLI AI agents in Zed editor.

[![macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://apple.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Zed Editor](https://img.shields.io/badge/editor-Zed-blue.svg)](https://zed.dev)

When running interactive AI agent CLIs (such as **Claude Code**, **Codex**, **Pi**, **Antigravity**, or **Grok**) inside [Zed](https://zed.dev)'s integrated terminal tabs, all tabs normally look identical with a static `>_` terminal icon.

**Zed Agent Terminal Integration** brings identity and visual feedback to your agent sessions:
- 🎨 **Branded Icons**: Distinctive vector icons for Claude Code, Codex, Pi, Antigravity, and Grok right in your Zed terminal tab headers.
- ⏳ **Active Thinking Spinner**: Real-time rotating spinner (`⠋`, `⠙`, `⠹`, `⠸`...) indicating when an agent is executing or generating responses, smoothly reverting to idle when waiting for input.
- 🧼 **Clean Session Titles**: Strips ANSI noise, CSI terminal queries, and DEC mode responses from tab titles.
- ⚡ **Zero External Dependencies**: Pure Python 3 standard library and native zsh hooks. No `pip install` required.
- 🛡️ **Safe Configuration**: Automatically merges font fallbacks into `~/.config/zed/settings.json` while 100% preserving your JSONC comments and custom formatting.

---

## Supported Agents

| Agent | CLI Invocation | PUA Glyph | Status Feedback |
| :--- | :--- | :--- | :--- |
| **Claude Code** | `claude` / `cc` | `\uF102` | Active Spinner + Clean Title |
| **OpenAI Codex** | `codex` | `\uF104` | Active Spinner + Dynamic Prompt |
| **Pi Agent** | `pi` | `\uE000` | Real-time Extension / PTY sync |
| **Google Antigravity** | `agy` | `\uF103` | Active Spinner + Sanitized Title |
| **xAI Grok** | `grok` | `\uF105` | Active Spinner + Dynamic Title |

---

## Quick Start (macOS)

### 1. Installation

Clone this repository and run the installer:

```bash
git clone https://github.com/Lanturewen/zed-agent-terminal.git
cd zed-agent-terminal
./install.sh
```

The installer will:
1. Copy `AgentIcons.ttf` to `~/Library/Fonts/AgentIcons.ttf`.
2. Install `agent-term-wrapper` to `~/.local/bin/agent-term-wrapper`.
3. Safely update `~/.config/zed/settings.json` with required font fallbacks (with backup).
4. Add shell integration to `~/.zshrc`.

### 2. Activate

Reload your shell or open a new terminal in Zed:

```bash
exec zsh
```

### 3. Verify

Run the built-in diagnostic tool:

```bash
./doctor.sh
```

---

## Manual Zed Settings (Optional)

If you prefer to configure Zed manually, add `"AgentIcons"` to font fallbacks in `~/.config/zed/settings.json`:

```jsonc
{
  "ui_font_fallbacks": ["AgentIcons"],
  "buffer_font_fallbacks": ["AgentIcons"],
  "terminal": {
    "font_fallbacks": ["AgentIcons"]
  }
}
```

---

## Packaging for Offline Deployment

To build a standalone tarball for another machine:

```bash
./package.sh
```

This creates `zed-agent-terminal-integration-1.0.0.tar.gz` and its `.sha256` checksum.

---

## Uninstallation

To completely remove the integration and restore all original configurations:

```bash
./uninstall.sh
```

---

## License

- Code: [MIT License](LICENSE)
- Icons: See [NOTICE.md](NOTICE.md) for brand and trademark notices.
