#!/usr/bin/env bash
# Symlink every skill folder in this repo into ~/.cursor/skills/
#
# Usage:
#   ./install.sh            # symlink all, refuse to overwrite existing entries
#   ./install.sh --force    # overwrite existing files/symlinks
#   ./install.sh <skill>    # symlink a single skill by name

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.cursor/skills"

force=false
filter=""

for arg in "$@"; do
  case "$arg" in
    --force|-f) force=true ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) filter="$arg" ;;
  esac
done

mkdir -p "$TARGET_DIR"

linked=0
skipped=0

for skill_path in "$REPO_DIR"/*/; do
  skill_name="$(basename "$skill_path")"

  case "$skill_name" in
    .git|node_modules) continue ;;
  esac

  if [ ! -f "$skill_path/SKILL.md" ]; then
    continue
  fi

  if [ -n "$filter" ] && [ "$skill_name" != "$filter" ]; then
    continue
  fi

  target="$TARGET_DIR/$skill_name"

  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ "$force" = "true" ]; then
      rm -rf "$target"
    else
      echo "skip: $skill_name (already exists at $target — use --force to overwrite)"
      skipped=$((skipped + 1))
      continue
    fi
  fi

  ln -s "$skill_path" "$target"
  echo "link: $skill_name -> $skill_path"
  linked=$((linked + 1))
done

echo
echo "linked: $linked, skipped: $skipped"

if [ -n "$filter" ] && [ "$linked" = "0" ] && [ "$skipped" = "0" ]; then
  echo "error: no skill named '$filter' found in $REPO_DIR" >&2
  exit 1
fi
