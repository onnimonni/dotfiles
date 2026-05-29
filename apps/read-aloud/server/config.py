import json
from pathlib import Path
from pydantic import BaseModel
from pydantic_settings import BaseSettings

CONFIG_DIR = Path.home() / ".config" / "read-aloud"
CONFIG_FILE = CONFIG_DIR / "config.json"
MODELS_DIR = Path.home() / ".cache" / "read-aloud" / "models"


class UserConfig(BaseModel):
    backend: str = "kokoro"
    voice: str = "af_heart"
    speed: float = 1.0

    @classmethod
    def load(cls) -> "UserConfig":
        if CONFIG_FILE.exists():
            return cls.model_validate_json(CONFIG_FILE.read_text())
        return cls()

    def save(self) -> None:
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        CONFIG_FILE.write_text(self.model_dump_json(indent=2))


class Settings(BaseSettings):
    host: str = "127.0.0.1"
    port: int = 7852
    models_dir: Path = MODELS_DIR
