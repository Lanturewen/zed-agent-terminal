#!/usr/bin/env bash
set -euo pipefail
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
python3 "$DIR/bin/configure-zed" "$@"
