#!/usr/bin/env bash
set -euo pipefail

package_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
home_dir="${HOME:?HOME is not set}"
zshrc="$home_dir/.zshrc"
marker_start="# >>> zed terminal agent status integration >>>"
marker_end="# <<< zed terminal agent status integration <<<"

if [[ -f "$zshrc" ]]; then
  tmp="$(mktemp)"
  awk -v start="$marker_start" -v end="$marker_end" '
    $0 == start { skip=1; next }
    $0 == end { skip=0; next }
    !skip { print }
  ' "$zshrc" > "$tmp"
  mv "$tmp" "$zshrc"
fi

restore_or_remove() {
  local destination="$1" source="$2" backup="${1}.zed-agent-integration.bak"
  if [[ -f "$backup" ]]; then
    mv "$backup" "$destination"
    printf 'Restored %s\n' "$destination"
  elif [[ -f "$destination" ]] && [[ -f "$source" ]] && cmp -s "$source" "$destination"; then
    rm -f "$destination"
    printf 'Removed %s\n' "$destination"
  elif [[ -f "$destination" ]]; then
    printf 'Kept %s (no backup was created or content changed)\n' "$destination"
  fi
}

restore_or_remove "$home_dir/.local/bin/agent-term-wrapper" "$package_dir/bin/agent-term-wrapper"
if [[ "$(uname -s)" == "Darwin" ]]; then restore_or_remove "$home_dir/Library/Fonts/AgentIcons.ttf" "$package_dir/assets/AgentIcons.ttf"; fi
if [[ -f "$home_dir/.pi/agent/extensions/auto-title.ts.zed-agent-integration.bak" ]]; then
  mv "$home_dir/.pi/agent/extensions/auto-title.ts.zed-agent-integration.bak" "$home_dir/.pi/agent/extensions/auto-title.ts"
elif [[ -f "$home_dir/.pi/agent/extensions/auto-title.ts" ]] && cmp -s "$package_dir/pi/auto-title.ts" "$home_dir/.pi/agent/extensions/auto-title.ts"; then
  rm -f "$home_dir/.pi/agent/extensions/auto-title.ts"
fi
printf 'Removed zed-agent-terminal-integration shell integration.\n'
