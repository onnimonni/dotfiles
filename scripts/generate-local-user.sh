#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${SCRIPT_DIR}/../local-user.nix"

hostname=$(scutil --get LocalHostName)
username=$(whoami)
fullName=$(id -F)

read -rp "Email address: " email

cat > "$OUTPUT_FILE" << EOF
{
  hostname = "${hostname}";
  username = "${username}";
  fullName = "${fullName}";
  email = "${email}";
}
EOF

echo "Created ${OUTPUT_FILE}"
