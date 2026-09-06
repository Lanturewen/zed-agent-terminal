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
  if [[ -z "$exe" ]]; then
    local cand
    for cand in \
      "$HOME/.local/bin/$name" \
      "$HOME/.npm-global/bin/$name" \
      "/opt/homebrew/bin/$name" \
      "/usr/local/bin/$name" \
      "$HOME/.claude/local/$name" \
      "$HOME/.antigravity/antigravity/bin/$name" \
      "$HOME/.grok/bin/$name"; do
      if [[ -x "$cand" ]]; then exe="$cand"; break; fi
    done
  fi
  if [[ -z "$exe" ]]; then print -u2 "zed-agent: executable not found: $name"; return 127; fi
  agent-term-wrapper "$icon" "$label" "$exe" "$@"
}

agy() { _zed_agent_run $'\uf103' "Antigravity" agy "$@"; }
claude() { export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1; _zed_agent_run $'\uf102' "Claude Code" claude "$@"; }
alias cc="claude"
grok() { _zed_agent_run $'\uf105' "Grok" grok "$@"; }
codex() { _zed_agent_run $'\uf104' "Codex" codex "$@"; }
# <<< zed terminal agent status integration <<<
