#!/usr/bin/env bash
# Pin darwin/packages/claude-code.json to the newest @anthropic-ai/claude-code
# release on npm. Run after the pin falls behind, then rebuild:
#
#   ./scripts/update-claude-code.sh
#   sudo darwin-rebuild switch --flake ~/.dotfiles/
set -euo pipefail

PIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/darwin/packages/claude-code.json"

current=$(jq -er '.version' "$PIN")
# Follow npm's latest tag independently of Homebrew's release channels.
latest=$(curl --retry 3 -fsSL https://registry.npmjs.org/@anthropic-ai/claude-code/latest |
  jq -er '.version | strings | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))')

if [ "$current" = "$latest" ]; then
  echo "claude-code already pinned to $latest"
  exit 0
fi

echo "claude-code $current -> $latest"

updated=$(jq --arg v "$latest" '.version = $v' "$PIN")

systems=$(jq -er '.platforms | keys[]' "$PIN")
while IFS= read -r system; do
  npm_platform=$(jq -er --arg s "$system" '.platforms[$s].npm' "$PIN")
  url="https://registry.npmjs.org/@anthropic-ai/claude-code-${npm_platform}/-/claude-code-${npm_platform}-${latest}.tgz"

  echo "  prefetching $npm_platform..."
  hash=$(nix store prefetch-file --json "$url" | jq -er '.hash | strings | select(startswith("sha256-"))')

  updated=$(jq --arg s "$system" --arg h "$hash" '.platforms[$s].hash = $h' <<<"$updated")
done <<<"$systems"

tmp_pin=$(mktemp "${PIN}.XXXXXX")
trap 'rm -f "$tmp_pin"' EXIT
printf '%s\n' "$updated" >"$tmp_pin"
chmod 644 "$tmp_pin"
mv "$tmp_pin" "$PIN"
echo "Updated $PIN"
