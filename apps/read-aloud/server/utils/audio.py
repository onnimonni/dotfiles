import io
import struct
import numpy as np


def pcm_to_wav(samples: np.ndarray, sample_rate: int) -> bytes:
    """Convert float32 or int16 numpy samples to WAV bytes."""
    if samples.dtype == np.float32:
        # Clip and convert float32 [-1.0, 1.0] to int16
        samples = np.clip(samples, -1.0, 1.0)
        pcm = (samples * 32767).astype(np.int16)
    elif samples.dtype == np.int16:
        pcm = samples
    else:
        raise ValueError(f"Unsupported dtype: {samples.dtype}")

    pcm_bytes = pcm.tobytes()
    num_channels = 1
    sample_width = 2  # 16-bit

    buf = io.BytesIO()
    # RIFF header
    data_size = len(pcm_bytes)
    buf.write(b"RIFF")
    buf.write(struct.pack("<I", 36 + data_size))
    buf.write(b"WAVE")
    # fmt chunk
    buf.write(b"fmt ")
    buf.write(struct.pack("<I", 16))  # chunk size
    buf.write(struct.pack("<H", 1))  # PCM format
    buf.write(struct.pack("<H", num_channels))
    buf.write(struct.pack("<I", sample_rate))
    buf.write(struct.pack("<I", sample_rate * num_channels * sample_width))  # byte rate
    buf.write(struct.pack("<H", num_channels * sample_width))  # block align
    buf.write(struct.pack("<H", sample_width * 8))  # bits per sample
    # data chunk
    buf.write(b"data")
    buf.write(struct.pack("<I", data_size))
    buf.write(pcm_bytes)
    return buf.getvalue()


def raw_pcm_to_wav(pcm_bytes: bytes, sample_rate: int) -> bytes:
    """Wrap raw 16-bit PCM bytes in a WAV container."""
    buf = io.BytesIO()
    num_channels = 1
    sample_width = 2
    data_size = len(pcm_bytes)

    buf.write(b"RIFF")
    buf.write(struct.pack("<I", 36 + data_size))
    buf.write(b"WAVE")
    buf.write(b"fmt ")
    buf.write(struct.pack("<I", 16))
    buf.write(struct.pack("<H", 1))
    buf.write(struct.pack("<H", num_channels))
    buf.write(struct.pack("<I", sample_rate))
    buf.write(struct.pack("<I", sample_rate * num_channels * sample_width))
    buf.write(struct.pack("<H", num_channels * sample_width))
    buf.write(struct.pack("<H", sample_width * 8))
    buf.write(b"data")
    buf.write(struct.pack("<I", data_size))
    buf.write(pcm_bytes)
    return buf.getvalue()
