let audio;
let wakeLock;

export function formatClock(totalSeconds) {
  const safe = Math.max(0, totalSeconds);
  const minutes = Math.floor(safe / 60);
  const seconds = safe % 60;
  return `${minutes}:${String(seconds).padStart(2, '0')}`;
}

export function setTimerOpen(open) {
  document.body.classList.toggle('timer-open', open);
}

export function setPhaseBar(bar, remaining, total) {
  const share = total > 0 ? 1 - remaining / total : 0;
  bar.style.width = `${Math.min(100, Math.max(0, share * 100))}%`;
}

export function prepareSound() {
  const Context = window.AudioContext || window.webkitAudioContext;
  if (!Context || audio) {
    return;
  }
  audio = new Context();
}

export function playTone(frequency) {
  if (!audio) {
    return;
  }
  const tone = audio.createOscillator();
  const gain = audio.createGain();
  tone.frequency.value = frequency;
  gain.gain.value = 0.04;
  tone.connect(gain);
  gain.connect(audio.destination);
  tone.start();
  tone.stop(audio.currentTime + 0.12);
}

export async function keepAwake() {
  try {
    wakeLock = await navigator.wakeLock?.request('screen');
  } catch {
    // Some browsers refuse a wake lock. The timer still runs.
    wakeLock = null;
  }
}

export function letSleep() {
  wakeLock?.release?.().catch(() => {});
  wakeLock = null;
}
