from collections.abc import AsyncIterator
from pathlib import Path

from .base import BackendInfo, TTSBackend
from ..utils.audio import pcm_to_wav
from ..utils.text import split_sentences
from ..config import MODELS_DIR

MODEL_FILE = MODELS_DIR / "kokoro-v1.0.onnx"
VOICES_FILE = MODELS_DIR / "voices-v1.0.bin"


class KokoroBackend(TTSBackend):
    def __init__(self) -> None:
        self._kokoro = None
        self._available = MODEL_FILE.exists() and VOICES_FILE.exists()

    def _load(self):
        if self._kokoro is None:
            from kokoro_onnx import Kokoro

            self._kokoro = Kokoro(str(MODEL_FILE), str(VOICES_FILE))
        return self._kokoro

    def info(self) -> BackendInfo:
        voices = []
        if self._available:
            try:
                voices = self._load().get_voices()
            except Exception:
                pass
        return BackendInfo(
            name="kokoro",
            available=self._available,
            voices=voices or [
                "af_heart", "af_alloy", "af_bella", "af_jessica", "af_nova",
                "af_river", "af_sarah", "af_sky", "am_adam", "am_echo",
                "am_eric", "am_michael", "am_onyx", "am_puck",
                "bf_alice", "bf_emma", "bf_lily", "bm_daniel", "bm_george",
            ],
            sample_rate=24000,
            description="Kokoro ONNX - high quality, ~3x realtime on M1",
        )

    async def generate(self, text: str, voice: str, speed: float) -> AsyncIterator[bytes]:
        kokoro = self._load()
        sentences = split_sentences(text)

        for sentence in sentences:
            async for samples, sample_rate in kokoro.create_stream(
                sentence, voice=voice, speed=speed, lang="en-us"
            ):
                yield pcm_to_wav(samples, sample_rate)
