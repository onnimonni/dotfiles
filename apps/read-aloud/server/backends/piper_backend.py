from collections.abc import AsyncIterator
import asyncio

from .base import BackendInfo, TTSBackend
from ..utils.audio import raw_pcm_to_wav
from ..utils.text import split_sentences
from ..config import MODELS_DIR

MODEL_FILE = MODELS_DIR / "en_US-lessac-medium.onnx"


class PiperBackend(TTSBackend):
    def __init__(self) -> None:
        self._voice = None
        self._available = MODEL_FILE.exists()

    def _load(self):
        if self._voice is None:
            from piper import PiperVoice

            self._voice = PiperVoice.load(str(MODEL_FILE))
        return self._voice

    def info(self) -> BackendInfo:
        return BackendInfo(
            name="piper",
            available=self._available,
            voices=["en_US-lessac-medium"],
            sample_rate=22050,
            description="Piper TTS - lightweight VITS, instant generation",
        )

    async def generate(self, text: str, voice: str, speed: float) -> AsyncIterator[bytes]:
        piper_voice = self._load()
        sentences = split_sentences(text)
        loop = asyncio.get_event_loop()

        from piper import SynthesisConfig

        syn_config = SynthesisConfig(length_scale=1.0 / speed if speed > 0 else 1.0)

        for sentence in sentences:
            # Run blocking piper synthesis in thread pool
            def _synthesize(s=sentence):
                pcm_chunks = []
                sample_rate = 22050
                for chunk in piper_voice.synthesize(s, syn_config=syn_config):
                    pcm_chunks.append(chunk.audio_int16_bytes)
                    sample_rate = chunk.sample_rate
                return b"".join(pcm_chunks), sample_rate

            pcm_bytes, sr = await loop.run_in_executor(None, _synthesize)
            yield raw_pcm_to_wav(pcm_bytes, sr)
