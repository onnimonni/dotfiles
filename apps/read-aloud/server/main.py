from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from .config import UserConfig
from .backends.base import TTSBackend

app = FastAPI(title="Read Aloud TTS", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registry of backends (lazy-loaded)
_backends: dict[str, TTSBackend] = {}


def _init_backends() -> None:
    if _backends:
        return
    try:
        from .backends.kokoro_backend import KokoroBackend

        _backends["kokoro"] = KokoroBackend()
    except Exception:
        pass
    try:
        from .backends.piper_backend import PiperBackend

        _backends["piper"] = PiperBackend()
    except Exception:
        pass
    try:
        from .backends.orpheus_backend import OrpheusBackend

        _backends["orpheus"] = OrpheusBackend()
    except Exception:
        pass


@app.on_event("startup")
async def startup():
    _init_backends()


@app.get("/health")
async def health():
    _init_backends()
    available = [name for name, b in _backends.items() if b.info().available]
    return {"status": "ok", "backends": available}


@app.get("/backends")
async def list_backends():
    _init_backends()
    return [
        {
            "name": b.info().name,
            "available": b.info().available,
            "voices": b.info().voices,
            "sample_rate": b.info().sample_rate,
            "description": b.info().description,
        }
        for b in _backends.values()
    ]


class TTSRequest(BaseModel):
    text: str
    backend: str = "kokoro"
    voice: str = "af_heart"
    speed: float = 1.0


@app.post("/tts")
async def tts(req: TTSRequest):
    _init_backends()
    backend = _backends.get(req.backend)
    if not backend:
        raise HTTPException(404, f"Backend '{req.backend}' not found")
    if not backend.info().available:
        raise HTTPException(503, f"Backend '{req.backend}' not available (models missing?)")

    async def stream():
        async for wav_chunk in backend.generate(req.text, req.voice, req.speed):
            yield wav_chunk

    return StreamingResponse(stream(), media_type="audio/wav")


@app.get("/config")
async def get_config():
    return UserConfig.load().model_dump()


@app.post("/config")
async def set_config(cfg: UserConfig):
    cfg.save()
    return cfg.model_dump()
