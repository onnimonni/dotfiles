"""Orpheus TTS backend via Ollama (experimental).

Requires: ollama running with legraphista/Orpheus:3b-ft-q4_k_m pulled.
Uses Ollama /api/generate with raw token output, then SNAC decoder for audio.

WARNING: This backend is experimental. Ollama may not expose raw token IDs
needed for SNAC decoding. Falls back to error if unsupported.
"""

from collections.abc import AsyncIterator

from .base import BackendInfo, TTSBackend
from ..utils.audio import pcm_to_wav
from ..utils.text import split_sentences

OLLAMA_URL = "http://localhost:11434"
MODEL_NAME = "legraphista/Orpheus:3b-ft-q4_k_m"
VOICES = ["tara", "leah", "jess", "leo", "dan", "mia", "zac", "zoe"]
SAMPLE_RATE = 24000


class OrpheusBackend(TTSBackend):
    def __init__(self) -> None:
        self._available = False
        self._snac = None
        try:
            import httpx

            # Quick check if Ollama is running (non-blocking init)
            self._available = True
        except ImportError:
            pass

    def _load_snac(self):
        if self._snac is None:
            import torch
            from snac import SNAC

            self._snac = SNAC.from_pretrained("hubertsiuzdak/snac_24khz").eval()
            if torch.backends.mps.is_available():
                self._snac = self._snac.to("mps")
        return self._snac

    def info(self) -> BackendInfo:
        return BackendInfo(
            name="orpheus",
            available=self._available,
            voices=VOICES,
            sample_rate=SAMPLE_RATE,
            description="Orpheus via Ollama - experimental, high quality, slower",
        )

    async def generate(self, text: str, voice: str, speed: float) -> AsyncIterator[bytes]:
        import httpx
        import torch
        import numpy as np

        snac = self._load_snac()
        device = next(snac.parameters()).device
        sentences = split_sentences(text)

        for sentence in sentences:
            prompt = f"<|audio|>{voice}: {sentence}"

            token_ids: list[int] = []
            async with httpx.AsyncClient(timeout=60.0) as client:
                async with client.stream(
                    "POST",
                    f"{OLLAMA_URL}/api/generate",
                    json={"model": MODEL_NAME, "prompt": prompt, "raw": True, "stream": True},
                ) as response:
                    response.raise_for_status()
                    import json

                    async for line in response.aiter_lines():
                        if not line:
                            continue
                        data = json.loads(line)
                        if "response" in data:
                            # Try to parse token as integer ID
                            token_text = data["response"].strip()
                            try:
                                token_ids.append(int(token_text))
                            except ValueError:
                                continue

            if not token_ids:
                continue

            # SNAC decode: reshape token IDs into codec layers
            # Orpheus uses 7 tokens per frame: [t1, t2, t3, t4, t5, t6, t7]
            # Layers: L1=[t1], L2=[t2,t4], L3=[t3,t5,t6,t7]
            n_frames = len(token_ids) // 7
            if n_frames == 0:
                continue

            token_ids = token_ids[: n_frames * 7]
            codes_l1, codes_l2, codes_l3 = [], [], []
            for i in range(n_frames):
                base = i * 7
                codes_l1.append(token_ids[base])
                codes_l2.append(token_ids[base + 1])
                codes_l3.append(token_ids[base + 2])
                codes_l2.append(token_ids[base + 3])
                codes_l3.append(token_ids[base + 4])
                codes_l3.append(token_ids[base + 5])
                codes_l3.append(token_ids[base + 6])

            with torch.no_grad():
                z = snac.decode(
                    torch.tensor([codes_l1], dtype=torch.long, device=device),
                    torch.tensor([codes_l2], dtype=torch.long, device=device),
                    torch.tensor([codes_l3], dtype=torch.long, device=device),
                )
                samples = z.squeeze().cpu().numpy().astype(np.float32)

            yield pcm_to_wav(samples, SAMPLE_RATE)
