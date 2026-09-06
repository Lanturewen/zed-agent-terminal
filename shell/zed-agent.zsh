# >>> zed terminal agent status integration >>>
# Managed by zed-agent-terminal-integration.
export PATH="$HOME/.local/bin:$PATH"

_zed_agent_run() {
  local icon="$1" label="$2" name="$3" fallback="$4"
  shift 4
  local exe=""
  exe="$(whence -p "$name" 2>/dev/null || true)"
  if [[ -z "$exe" && -n "$fallback" && -x "$fallback" ]]; then exe="$fallback"; fi
  if [[ -z "$exe" ]]; then print -u2 "zed-agent: executable not found: $name"; return 127; fi
  agent-term-wrapper "$icon" "$label" "$exe" "$@"
}

agy() { _zed_agent_run $'\uf103' "Antigravity" agy "$HOME/.antigravity/antigravity/bin/agy" "$@"; }
claude() { CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1 _zed_agent_run $'\uf102' "Claude Code" claude "$HOME/.claude/local/claude" "$@"; }
alias cc="claude"
grok() { _zed_agent_run $'\uf105' "Grok" grok "$HOME/.grok/bin/grok" "$@"; }
codex() { _zed_agent_run $'\uf104' "Codex" codex "$HOME/.npm-global/bin/codex" "$@"; }
# <<< zed terminal agent status integration <<<
