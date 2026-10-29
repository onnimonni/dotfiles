#!/usr/bin/env bash
# Print "true" if this Mac can run DwarfStar (antirez/ds4) resident models, else "false".
# Needs Apple Silicon (Metal), macOS 26+ (SDK 26 build) and >= 96 GB unified
# memory (DeepSeek V4 Flash Q2 is ~81 GiB). Smaller Macs only work with slow SSD streaming.
set -euo pipefail

MIN_MEM_GIB=96

arm64=$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)
mem_gib=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
macos_major=$(sw_vers -productVersion | cut -d. -f1)

if [ "$arm64" = 1 ] && [ "$mem_gib" -ge "$MIN_MEM_GIB" ] && [ "$macos_major" -ge 26 ]; then
  echo true
else
  echo false
fi
