import re


def split_sentences(text: str) -> list[str]:
    """Split text into sentences for chunked TTS generation."""
    # Split on sentence-ending punctuation followed by whitespace
    parts = re.split(r"(?<=[.!?])\s+", text.strip())
    # Filter empty strings and merge very short fragments with previous
    sentences: list[str] = []
    for part in parts:
        part = part.strip()
        if not part:
            continue
        if sentences and len(part) < 20:
            sentences[-1] += " " + part
        else:
            sentences.append(part)
    return sentences if sentences else [text.strip()]
