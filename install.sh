#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) printf 'Usage: %s [--dry-run]\n' "$0"; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

home_dir="${HOME:?HOME is not set}"
bin_dir="$home_dir/.local/bin"
wrapper="$bin_dir/agent-term-wrapper"
font_dir="$home_dir/Library/Fonts"
font="$font_dir/AgentIcons.ttf"
zshrc="$home_dir/.zshrc"
marker_start="# >>> zed terminal agent status integration >>>"
marker_end="# <<< zed terminal agent status integration <<<"

run() { if (( DRY_RUN )); then printf '+ %s\n' "$*"; else "$@"; fi; }

backup_if_needed() {
  local source="$1" destination="$2" backup="${2}.zed-agent-integration.bak"
  if [[ -e "$destination" ]] && ! cmp -s "$source" "$destination" && [[ ! -e "$backup" ]]; then
    run cp -p "$destination" "$backup"
  fi
}

run mkdir -p "$bin_dir"
backup_if_needed "$PACKAGE_DIR/bin/agent-term-wrapper" "$wrapper"
run cp "$PACKAGE_DIR/bin/agent-term-wrapper" "$wrapper"
run chmod 755 "$wrapper"

if [[ "$(uname -s)" == "Darwin" ]]; then
  run mkdir -p "$font_dir"
  backup_if_needed "$PACKAGE_DIR/assets/AgentIcons.ttf" "$font"
  run cp "$PACKAGE_DIR/assets/AgentIcons.ttf" "$font"
else
  printf 'Warning: AgentIcons.ttf was not installed; this package currently targets macOS.\n' >&2
fi

if [[ -d "$home_dir/.pi/agent/extensions" ]]; then
  backup_if_needed "$PACKAGE_DIR/pi/auto-title.ts" "$home_dir/.pi/agent/extensions/auto-title.ts"
  run cp "$PACKAGE_DIR/pi/auto-title.ts" "$home_dir/.pi/agent/extensions/auto-title.ts"
fi

if [[ -f "$zshrc" ]]; then
  tmp="$(mktemp)"
  awk -v start="$marker_start" -v end="$marker_end" '
    $0 == start { skip=1; next }
    $0 == end { skip=0; next }
    !skip { print }
  ' "$zshrc" > "$tmp"
  if (( DRY_RUN )); then
    printf '+ replace managed block in %s\n' "$zshrc"
    rm -f "$tmp"
  else
    mv "$tmp" "$zshrc"
  fi
else
  run touch "$zshrc"
fi

if (( DRY_RUN )); then
  printf '+ append managed zsh block to %s\n' "$zshrc"
else
  cat "$PACKAGE_DIR/shell/zed-agent.zsh" >> "$zshrc"
fi

if [[ -x "$PACKAGE_DIR/bin/configure-zed" ]]; then
  if (( DRY_RUN )); then
    run "$PACKAGE_DIR/bin/configure-zed" --dry-run
  else
    python3 "$PACKAGE_DIR/bin/configure-zed"
  fi
fi

printf 'Installed zed-agent-terminal-integration.\n'
printf 'Start a new shell with: exec zsh\n'
printf 'Then diagnose with: %s/doctor.sh\n' "$PACKAGE_DIR"
