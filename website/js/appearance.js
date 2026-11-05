const skins = [
  { id: 'night', name: 'Night', text: 'Black, white, no extra colour.' },
  { id: 'iron', name: 'Iron', text: 'Charcoal gym floor and burnt orange.' },
  { id: 'steel', name: 'Steel', text: 'The same charcoal, with electric blue.' },
  { id: 'studio', name: 'Studio', text: 'Warm paper for daytime at a desk.' },
];

const skinIds = skins.map((skin) => skin.id);
const themeIds = ['dark', 'light', 'system'];

export function loadSkin() {
  const value = localStorage.getItem('stackfit.skin');
  return skinIds.includes(value) ? value : 'night';
}

export function loadTheme() {
  const value = localStorage.getItem('stackfit.theme');
  return themeIds.includes(value) ? value : 'dark';
}

export function resolveTheme(theme, prefersDark) {
  if (theme === 'light') {
    return 'light';
  }
  if (theme === 'dark') {
    return 'dark';
  }
  return prefersDark ? 'dark' : 'light';
}

export function applyAppearance({
  skin = loadSkin(),
  theme = loadTheme(),
  prefersDark = matchMedia('(prefers-color-scheme: dark)').matches,
} = {}) {
  const resolved = resolveTheme(theme, prefersDark);
  document.documentElement.dataset.skin = skin;
  document.documentElement.dataset.theme = resolved;
  const color = getComputedStyle(document.documentElement).getPropertyValue('--background').trim();
  for (const meta of document.querySelectorAll('meta[name="theme-color"]')) {
    meta.content = color;
    meta.removeAttribute('media');
  }
}

export function installAppearance(app) {
  document.querySelector('#open-appearance').addEventListener('click', () => openAppearance(app));
  document.querySelector('#close-appearance').addEventListener('click', () => closeAppearance(app));
  matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (event) => {
    if (loadTheme() === 'system') {
      applyAppearance({ prefersDark: event.matches });
    }
  });
  document.querySelector('#theme-choices').addEventListener('click', (event) => {
    const button = event.target.closest('[data-theme]');
    if (!button || !themeIds.includes(button.dataset.theme)) {
      return;
    }
    localStorage.setItem('stackfit.theme', button.dataset.theme);
    applyAppearance();
    renderChoices();
  });
  renderChoices();
  if (location.hash === '#appearance') {
    openAppearance(app);
  }
}

export function hideAppearance() {
  const page = document.querySelector('#appearance');
  if (page) {
    page.hidden = true;
  }
}

function openAppearance(app) {
  app.stopTimers?.();
  document.querySelector('#signed-in').hidden = true;
  document.querySelector('#signed-out').hidden = true;
  document.querySelector('#share-view').hidden = true;
  document.querySelector('#tabata').hidden = true;
  document.querySelector('#appearance').hidden = false;
  document.title = 'Appearance · StackFit';
  if (location.hash !== '#appearance') {
    history.replaceState({}, '', `${location.pathname}${location.search}#appearance`);
  }
  renderChoices();
}

function closeAppearance(app) {
  hideAppearance();
  if (location.hash === '#appearance') {
    history.replaceState({}, '', location.pathname + location.search);
  }
  app.returnFromAppearance();
}

function renderChoices() {
  const skin = loadSkin();
  const theme = loadTheme();
  const list = document.querySelector('#skin-choices');
  list.replaceChildren(...skins.map((item) => skinCard(item, item.id === skin)));
  for (const button of document.querySelectorAll('#theme-choices [data-theme]')) {
    button.setAttribute('aria-pressed', String(button.dataset.theme === theme));
  }
}

function skinCard(item, selected) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'skin-card';
  button.dataset.skin = item.id;
  button.setAttribute('aria-pressed', String(selected));
  const preview = document.createElement('span');
  preview.className = 'skin-preview';
  preview.dataset.skin = item.id;
  const title = document.createElement('strong');
  title.textContent = item.name;
  const text = document.createElement('span');
  text.className = 'meta';
  text.textContent = item.text;
  button.append(preview, title, text);
  button.addEventListener('click', () => {
    localStorage.setItem('stackfit.skin', item.id);
    applyAppearance();
    renderChoices();
  });
  return button;
}
