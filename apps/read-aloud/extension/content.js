(() => {
  "use strict";

  const DEFAULTS = { backend: "kokoro", voice: "af_heart", speed: 1.0, port: 7852 };
  let settings = { ...DEFAULTS };
  let abortController = null;
  let audioCtx = null;
  let scheduledEnd = 0;
  let isPlaying = false;

  // Load saved settings
  chrome.storage.sync.get(DEFAULTS, (s) => { settings = s; });
  chrome.storage.onChanged.addListener((changes) => {
    for (const [k, v] of Object.entries(changes)) {
      if (k in settings) settings[k] = v.newValue;
    }
  });

  // Inject floating button
  const btn = document.createElement("button");
  btn.id = "read-aloud-btn";
  btn.textContent = "\u{1F50A}";
  btn.title = "Read article aloud";
  document.body.appendChild(btn);

  btn.addEventListener("click", () => {
    if (isPlaying) {
      stopPlayback();
    } else {
      startPlayback();
    }
  });

  function extractText() {
    const clone = document.cloneNode(true);
    const article = new Readability(clone).parse();
    if (article && article.textContent && article.textContent.length > 50) {
      return DOMPurify.sanitize(article.textContent, { ALLOWED_TAGS: [] });
    }
    // Fallback: selected text or body text
    const sel = window.getSelection().toString().trim();
    if (sel.length > 20) return sel;
    return document.body.innerText.substring(0, 10000);
  }

  async function startPlayback() {
    const text = extractText();
    if (!text) return;

    isPlaying = true;
    btn.classList.add("loading");
    btn.textContent = "\u23F3";

    abortController = new AbortController();
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    scheduledEnd = 0;

    const baseUrl = `http://127.0.0.1:${settings.port}`;

    try {
      const resp = await fetch(`${baseUrl}/tts`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          text,
          backend: settings.backend,
          voice: settings.voice,
          speed: settings.speed,
        }),
        signal: abortController.signal,
      });

      if (!resp.ok) {
        throw new Error(`TTS server error: ${resp.status}`);
      }

      btn.classList.remove("loading");
      btn.classList.add("playing");
      btn.textContent = "\u23F9";

      await processStream(resp.body.getReader());
    } catch (e) {
      if (e.name !== "AbortError") {
        console.error("Read Aloud:", e);
      }
    } finally {
      btn.classList.remove("loading", "playing");
      btn.textContent = "\u{1F50A}";
      isPlaying = false;
    }
  }

  async function processStream(reader) {
    let buffer = new Uint8Array(0);

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      // Append new data
      const combined = new Uint8Array(buffer.length + value.length);
      combined.set(buffer);
      combined.set(value, buffer.length);
      buffer = combined;

      // Extract complete WAV chunks (split on RIFF headers)
      while (true) {
        const wavData = extractWav(buffer);
        if (!wavData) break;
        buffer = buffer.slice(wavData.length);
        await queueAudio(wavData);
      }
    }

    // Process any remaining buffer as final WAV
    if (buffer.length > 44) {
      await queueAudio(buffer);
    }
  }

  function extractWav(data) {
    if (data.length < 44) return null;

    // Verify RIFF header
    if (data[0] !== 0x52 || data[1] !== 0x49 || data[2] !== 0x46 || data[3] !== 0x46) {
      return null;
    }

    // Read chunk size (bytes 4-7, little-endian)
    const chunkSize = data[4] | (data[5] << 8) | (data[6] << 16) | (data[7] << 24);
    const totalSize = chunkSize + 8;

    if (data.length < totalSize) return null;
    return data.slice(0, totalSize);
  }

  async function queueAudio(wavBytes) {
    if (!audioCtx || audioCtx.state === "closed") return;

    try {
      const audioBuffer = await audioCtx.decodeAudioData(wavBytes.buffer.slice(
        wavBytes.byteOffset, wavBytes.byteOffset + wavBytes.byteLength
      ));
      const source = audioCtx.createBufferSource();
      source.buffer = audioBuffer;
      source.connect(audioCtx.destination);

      const startTime = Math.max(audioCtx.currentTime, scheduledEnd);
      source.start(startTime);
      scheduledEnd = startTime + audioBuffer.duration;
    } catch (e) {
      console.warn("Read Aloud: failed to decode audio chunk", e);
    }
  }

  function stopPlayback() {
    if (abortController) {
      abortController.abort();
      abortController = null;
    }
    if (audioCtx) {
      audioCtx.close().catch(() => {});
      audioCtx = null;
    }
    isPlaying = false;
    scheduledEnd = 0;
    btn.classList.remove("loading", "playing");
    btn.textContent = "\u{1F50A}";
  }
})();
