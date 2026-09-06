#!/usr/bin/env bash
set -u

home_dir="${HOME:?HOME is not set}"
zshrc="$home_dir/.zshrc"
printf 'platform: %s %s\n' "$(uname -s)" "$(uname -m)"
printf 'home: %s\n' "$home_dir"
printf 'wrapper: '
if [[ -x "$home_dir/.local/bin/agent-term-wrapper" ]]; then printf 'ok (%s)\n' "$home_dir/.local/bin/agent-term-wrapper"; else printf 'missing\n'; fi
printf 'font: '
if [[ -f "$home_dir/Library/Fonts/AgentIcons.ttf" ]]; then printf 'ok (%s)\n' "$home_dir/Library/Fonts/AgentIcons.ttf"; else printf 'missing\n'; fi
printf 'shell block: '
if [[ -f "$zshrc" ]] && grep -q '^# >>> zed terminal agent status integration >>>$' "$zshrc"; then printf 'ok\n'; else printf 'missing\n'; fi
for name in codex claude agy grok; do
  printf '%s: ' "$name"
  path="$(zsh -fc "whence -p $name" 2>/dev/null || true)"
  if [[ -n "$path" ]]; then printf '%s\n' "$path"; else printf 'not found\n'; fi
done
printf 'zed settings fallback: '
settings="$home_dir/.config/zed/settings.json"
if [[ -f "$settings" ]] && grep -q 'AgentIcons' "$settings"; then printf 'present\n'; else printf 'not configured\n'; fi
printf 'native terminal tab icon: unchanged (>_); requires upstream Zed terminal metadata support\n'
