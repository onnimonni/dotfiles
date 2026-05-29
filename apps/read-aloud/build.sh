#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$SCRIPT_DIR/server"
MODELS_DIR="$HOME/.cache/read-aloud/models"

echo "=== Read Aloud: Master Build ==="

# 1. Install Python deps
echo ""
echo "==> Installing Python dependencies..."
cd "$SERVER_DIR"
uv sync --extra all 2>/dev/null || uv sync
echo "Done."

# 2. Download models
echo ""
echo "==> Downloading TTS models..."
mkdir -p "$MODELS_DIR"

# Kokoro ONNX model + voices
KOKORO_MODEL="$MODELS_DIR/kokoro-v1.0.onnx"
KOKORO_VOICES="$MODELS_DIR/voices-v1.0.bin"

if [ ! -f "$KOKORO_MODEL" ]; then
  echo "Downloading Kokoro model (~350MB)..."
  curl -L "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx" \
    -o "$KOKORO_MODEL"
else
  echo "Kokoro model already exists, skipping."
fi

if [ ! -f "$KOKORO_VOICES" ]; then
  echo "Downloading Kokoro voices..."
  curl -L "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin" \
    -o "$KOKORO_VOICES"
else
  echo "Kokoro voices already exist, skipping."
fi

# Piper model + config
PIPER_MODEL="$MODELS_DIR/en_US-lessac-medium.onnx"
PIPER_CONFIG="$MODELS_DIR/en_US-lessac-medium.onnx.json"

if [ ! -f "$PIPER_MODEL" ]; then
  echo "Downloading Piper model..."
  curl -L "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx" \
    -o "$PIPER_MODEL"
else
  echo "Piper model already exists, skipping."
fi

if [ ! -f "$PIPER_CONFIG" ]; then
  echo "Downloading Piper config..."
  curl -L "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json" \
    -o "$PIPER_CONFIG"
else
  echo "Piper config already exists, skipping."
fi

# Orpheus via Ollama (optional)
if command -v ollama &>/dev/null; then
  echo "Pulling Orpheus model via Ollama..."
  ollama pull legraphista/Orpheus:3b-ft-q4_k_m || echo "WARNING: Ollama pull failed (is Ollama running?)"
else
  echo "Ollama not found, skipping Orpheus model."
fi

echo ""
echo "==> Models downloaded to: $MODELS_DIR"

# 3. Safari extension (optional)
if [ "${BUILD_SAFARI:-0}" = "1" ]; then
  echo ""
  echo "==> Building Safari extension..."
  bash "$SCRIPT_DIR/safari/build.sh"
else
  echo ""
  echo "==> Skipping Safari build (set BUILD_SAFARI=1 to enable)"
fi

echo ""
echo "=== Build complete ==="
echo ""
echo "To start the TTS server:"
echo "  cd $SERVER_DIR && uv run uvicorn server.main:app --host 127.0.0.1 --port 7852"
echo ""
echo "To load Chrome extension:"
echo "  chrome://extensions > Load unpacked > $SCRIPT_DIR/extension"
echo ""
echo "To test:"
echo "  curl http://localhost:7852/health"
