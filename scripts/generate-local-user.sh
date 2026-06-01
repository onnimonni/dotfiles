#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${SCRIPT_DIR}/../local-user.nix"

hostname=$(scutil --get LocalHostName)
username=$(whoami)
fullName=$(id -F)

read -rp "Email address: " email
read -rp "Cloudflare zone for Mac Studio share tunnel (empty = disable): " shareDomain

if [ -n "${shareDomain}" ]; then
  shareLine="  shareMacDomain = \"${shareDomain}\";"
else
  shareLine="  shareMacDomain = null;"
fi

cat > "$OUTPUT_FILE" << EOF
{
  hostname = "${hostname}";
  username = "${username}";
  fullName = "${fullName}";
  email = "${email}";
${shareLine}
}
EOF

echo "Created ${OUTPUT_FILE}"
