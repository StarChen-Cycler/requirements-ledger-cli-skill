#!/usr/bin/env bash
# Install the requirements-ledger-cli skill into an agent skills directory.
# Usage: ./install.sh [target-skills-dir]
set -euo pipefail

SKILL_NAME="requirements-ledger-cli"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$(cd "$HERE/.." && pwd)"

if [ ! -f "$SOURCE/SKILL.md" ]; then
  echo "error: SKILL.md not found next to $HERE" >&2
  exit 1
fi

if [ "$#" -ge 1 ] && [ -n "${1:-}" ]; then
  TARGET="$1"
else
  TARGET=""
  for candidate in "$HOME/.agents/skills" "$HOME/.Codex/skills" "$HOME/.claude/skills"; do
    if [ -d "$candidate" ]; then
      TARGET="$candidate"
      break
    fi
  done
  if [ -z "$TARGET" ]; then
    TARGET="$HOME/.agents/skills"
    echo "no known skills directory found; creating $TARGET"
  fi
fi

mkdir -p "$TARGET"
DEST="$TARGET/$SKILL_NAME"
if [ -d "$DEST" ]; then
  echo "replacing existing $DEST"
  rm -rf "$DEST"
fi
cp -R "$SOURCE" "$DEST"
rm -rf "$DEST/scripts"

echo "installed: $DEST/SKILL.md"
echo "verify:    test -f \"$DEST/SKILL.md\" && sed -n '1,5p' \"$DEST/SKILL.md\""
echo "next:      restart the agent session so the skill catalog reloads"
