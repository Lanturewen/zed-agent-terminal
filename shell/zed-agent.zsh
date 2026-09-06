# >>> zed terminal agent status integration >>>
# Managed by zed-agent-terminal-integration.
export PATH="$HOME/.local/bin:$PATH"

# Ensure aliases do not shadow our wrapper functions
unalias agy claude cc grok codex 2>/dev/null || true

_zed_agent_run() {
  local icon="$1" label="$2" name="$3"
  shift 3
  local exe=""
  exe="$(whence -p "$name" 2>/dev/null || true)"
  while [[ -z "$exe" && $# -gt 0 ]]; do
    if [[ -x "$1" ]]; then exe="$1"; break; fi
    shift
  done
  if [[ -z "$exe" ]]; then print -u2 "zed-agent: executable not found: $name"; return 127; fi
  agent-term-wrapper "$icon" "$label" "$exe" "$@"
}

agy() {
  _zed_agent_run $'\uf103' "Antigravity" agy \
    "$HOME/.antigravity/antigravity/bin/agy" \
    "$HOME/.local/bin/agy" \
    "$@"
}

claude() {
  export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1
  _zed_agent_run $'\uf102' "Claude Code" claude \
    "$HOME/.local/bin/claude" \
    "$HOME/.claude/local/claude" \
    "/opt/homebrew/bin/claude" \
    "/usr/local/bin/claude" \
    "$HOME/.npm-global/bin/claude" \
    "$@"
}
alias cc="claude"

grok() {
  _zed_agent_run $'\uf105' "Grok" grok \
    "$HOME/.grok/bin/grok" \
    "$HOME/.local/bin/grok" \
    "$@"
}

codex() {
  _zed_agent_run $'\uf104' "Codex" codex \
    "$HOME/.npm-global/bin/codex" \
    "$HOME/.local/bin/codex" \
    "/usr/local/bin/codex" \
    "/opt/homebrew/bin/codex" \
    "$@"
}
# <<< zed terminal agent status integration <<<
