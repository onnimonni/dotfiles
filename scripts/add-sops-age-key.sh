#!/usr/bin/env bash
# Lets this machine decrypt secrets/secrets.yaml (sops-nix needs it during
# darwin-rebuild activation):
#   1. creates ~/.config/sops/age/keys.txt if missing
#   2. adds its public key to .sops.yaml as a recipient
#   3. re-encrypts the secrets with the YubiKey from .sops.yaml (PIN + touch)
# Safe to re-run: does nothing when the key can already decrypt the secrets.
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
KEY_FILE="$HOME/.config/sops/age/keys.txt"
SOPS_CONFIG="$DOTFILES/.sops.yaml"
SECRETS="$DOTFILES/secrets/secrets.yaml"

# Run the tools from nixpkgs so this works before the first darwin-rebuild
if [ -z "${ADD_SOPS_AGE_KEY_IN_NIX_SHELL:-}" ]; then
  export ADD_SOPS_AGE_KEY_IN_NIX_SHELL=1
  exec nix shell nixpkgs#age nixpkgs#sops nixpkgs#age-plugin-yubikey nixpkgs#yq-go \
    -c bash "$0" "$@"
fi

if [ ! -f "$KEY_FILE" ]; then
  echo "Creating age key $KEY_FILE"
  mkdir -p "$(dirname "$KEY_FILE")"
  (umask 077 && age-keygen -o "$KEY_FILE")
fi

public_key=$(age-keygen -y "$KEY_FILE")

if grep -qF "recipient: $public_key" "$SECRETS"; then
  echo "sops: this machine's age key can already decrypt the secrets ✓"
  exit 0
fi

host=$(scutil --get LocalHostName 2>/dev/null || hostname -s)

if ! yq -e ".keys[] | select(. == \"$public_key\")" "$SOPS_CONFIG" >/dev/null 2>&1; then
  anchor="host_$(printf '%s' "$host" | tr '[:upper:]-' '[:lower:]_')"
  if yq -e ".keys[] | select(anchor == \"$anchor\")" "$SOPS_CONFIG" >/dev/null 2>&1; then
    anchor="${anchor}_$(date +%Y%m%d)"
  fi

  echo "Adding $public_key to .sops.yaml as $anchor"
  yq -i "
    .keys += [\"$public_key\"] |
    .keys[-1] anchor = \"$anchor\" |
    .keys[-1] head_comment = \"$host ~/.config/sops/age/keys.txt, added $(date +%Y-%m-%d)\" |
    .creation_rules[0].key_groups[0].age += [\"$anchor\"] |
    .creation_rules[0].key_groups[0].age[-1] alias = \"$anchor\"
  " "$SOPS_CONFIG"
fi

# Re-encrypting needs a key that can decrypt already: the YubiKey recipient
yubikey_recipient=$(grep -oE 'age1yubikey1[a-z0-9]+' "$SOPS_CONFIG" | head -n 1)

echo ""
echo "=== YubiKey ==="
echo "Plug in the YubiKey for $yubikey_recipient to re-encrypt the secrets."
until age-plugin-yubikey --list 2>/dev/null | grep -qF "$yubikey_recipient"; do
  printf "YubiKey not found. Plug it in and press Enter... "
  read -r
done

identity=$(mktemp)
trap 'rm -f "$identity"' EXIT

# The identity file only references the YubiKey slot, it holds no secret
age-plugin-yubikey --identity >"$identity" 2>/dev/null

echo "Enter the YubiKey PIN and touch it when it blinks."
SOPS_AGE_KEY_FILE="$identity" sops updatekeys -y "$SECRETS"

echo ""
echo "sops: $host can now decrypt the secrets. Commit the change:"
echo "  git -C $DOTFILES add .sops.yaml secrets/secrets.yaml"
echo "  git -C $DOTFILES commit -m \"sops: add $host age key\""
