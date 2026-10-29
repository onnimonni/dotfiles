#!/usr/bin/env bash
# Pin darwin/packages/ds4/ds4.json to the newest antirez/ds4 commit, then rebuild:
#
#   ./scripts/update-ds4.sh
#   sudo darwin-rebuild switch --flake ~/.dotfiles/
set -euo pipefail

PIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/darwin/packages/ds4/ds4.json"

current=$(jq -er '.rev' "$PIN")
latest=$(gh api repos/antirez/ds4/commits/HEAD --jq '.sha')

if [ "$current" = "$latest" ]; then
  echo "ds4 already pinned to $latest"
  exit 0
fi

date=$(gh api "repos/antirez/ds4/commits/$latest" --jq '.commit.committer.date[:10]')
hash=$(nix flake prefetch "github:antirez/ds4/$latest" --json | jq -er '.hash | strings | select(startswith("sha256-"))')

echo "ds4 ${current:0:7} -> ${latest:0:7} ($date)"

tmp_pin=$(mktemp "${PIN}.XXXXXX")
trap 'rm -f "$tmp_pin"' EXIT
jq -n --arg v "0-unstable-$date" --arg r "$latest" --arg h "$hash" \
  '{version: $v, rev: $r, hash: $h}' >"$tmp_pin"
chmod 644 "$tmp_pin"
mv "$tmp_pin" "$PIN"
echo "Updated $PIN"
