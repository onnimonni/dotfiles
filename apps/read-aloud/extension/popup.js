const DEFAULTS = { backend: "kokoro", voice: "af_heart", speed: 1.0, port: 7852 };

const $backend = document.getElementById("backend");
const $voice = document.getElementById("voice");
const $speed = document.getElementById("speed");
const $speedVal = document.getElementById("speed-val");
const $port = document.getElementById("port");
const $status = document.getElementById("status");

let backendsData = [];

async function init() {
  const saved = await chrome.storage.sync.get(DEFAULTS);
  $speed.value = saved.speed;
  $speedVal.textContent = saved.speed;
  $port.value = saved.port;

  await fetchBackends(saved.port);

  // Select saved values
  $backend.value = saved.backend;
  await updateVoices();
  $voice.value = saved.voice;
}

async function fetchBackends(port) {
  try {
    const resp = await fetch(`http://127.0.0.1:${port}/backends`);
    backendsData = await resp.json();

    $backend.innerHTML = "";
    for (const b of backendsData) {
      const opt = document.createElement("option");
      opt.value = b.name;
      opt.textContent = b.name + (b.available ? "" : " (unavailable)");
      opt.disabled = !b.available;
      $backend.appendChild(opt);
    }

    $status.textContent = "Connected";
    $status.className = "ok";
  } catch {
    $status.textContent = "Server offline";
    $status.className = "err";

    // Fallback options
    $backend.innerHTML = '<option value="kokoro">kokoro</option><option value="piper">piper</option><option value="orpheus">orpheus</option>';
  }
}

async function updateVoices() {
  const selected = $backend.value;
  const bd = backendsData.find((b) => b.name === selected);
  $voice.innerHTML = "";

  const voices = bd ? bd.voices : ["af_heart"];
  for (const v of voices) {
    const opt = document.createElement("option");
    opt.value = v;
    opt.textContent = v;
    $voice.appendChild(opt);
  }
}

function save() {
  chrome.storage.sync.set({
    backend: $backend.value,
    voice: $voice.value,
    speed: parseFloat($speed.value),
    port: parseInt($port.value, 10),
  });
}

$backend.addEventListener("change", async () => {
  await updateVoices();
  save();
});
$voice.addEventListener("change", save);
$speed.addEventListener("input", () => {
  $speedVal.textContent = parseFloat($speed.value).toFixed(1);
  save();
});
$port.addEventListener("change", async () => {
  save();
  await fetchBackends(parseInt($port.value, 10));
});

init();
