from abc import ABC, abstractmethod
from collections.abc import AsyncIterator
from dataclasses import dataclass


@dataclass
class BackendInfo:
    name: str
    available: bool
    voices: list[str]
    sample_rate: int
    description: str


class TTSBackend(ABC):
    @abstractmethod
    async def generate(self, text: str, voice: str, speed: float) -> AsyncIterator[bytes]:
        """Yield complete WAV bytes per sentence."""
        ...

    @abstractmethod
    def info(self) -> BackendInfo:
        """Return backend metadata."""
        ...
