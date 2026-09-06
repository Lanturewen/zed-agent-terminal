#!/usr/bin/env bash
set -euo pipefail

package_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
version="$(tr -d '[:space:]' < "$package_dir/VERSION")"
name="zed-agent-terminal-integration-${version}"
output_dir="$(dirname "$package_dir")"
archive="$output_dir/${name}.tar.gz"

tar -czf "$archive" --exclude='*__pycache__*' --exclude='*.pyc' -C "$output_dir" "$(basename "$package_dir")"
(cd "$output_dir" && shasum -a 256 "$(basename "$archive")" > "$(basename "$archive").sha256")
printf '%s\n' "$archive"
printf '%s\n' "$archive.sha256"
