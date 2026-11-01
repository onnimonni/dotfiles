#!/bin/zsh
# Apply the ds4 "Ctrl+C twice to close ds4 and ds4-agent" patch to the ds4
# checkout and rebuild the affected binaries.
#
# Usage: ~/.dotfiles/scripts/apply-ds4-ctrl-c-twice.sh [DS4_HOME]
#
# The ds4 binaries are built by `make` from the checkout in ~/Projects/ds4
# (see darwin/system/programs/ds4.nix).  This script applies the patch stored
# in ~/.dotfiles/patches/ds4-ctrl-c-twice.patch and runs `make ds4 ds4-agent`.

set -e

DS4_HOME="${1:-${DS4_HOME:-$HOME/Projects/ds4}}"
PATCH="$HOME/.dotfiles/patches/ds4-ctrl-c-twice.patch"

if [ ! -d "$DS4_HOME" ]; then
  echo "ds4 checkout not found at $DS4_HOME" >&2
  exit 1
fi
if [ ! -f "$PATCH" ]; then
  echo "patch not found at $PATCH" >&2
  exit 1
fi

cd "$DS4_HOME"

# Already applied?  git apply --check fails on a re-applied patch.
if git apply --check "$PATCH" 2>/dev/null; then
  git apply "$PATCH"
  echo "Applied $PATCH"
else
  # If the reverse applies cleanly the patch is already in the tree.
  if git apply --reverse --check "$PATCH" 2>/dev/null; then
    echo "Patch already applied to $DS4_HOME"
  else
    echo "Patch does not apply cleanly to $DS4_HOME (tree may be modified)" >&2
    exit 1
  fi
fi

make ds4 ds4-agent
echo "Rebuilt ds4 and ds4-agent. Ctrl+C twice now closes both."
