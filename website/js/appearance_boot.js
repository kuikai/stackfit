(() => {
  const skins = ['night', 'iron', 'steel', 'studio'];
  const themes = ['dark', 'light', 'system'];
  const storedSkin = localStorage.getItem('stackfit.skin');
  const storedTheme = localStorage.getItem('stackfit.theme');
  const skin = skins.includes(storedSkin) ? storedSkin : 'night';
  const theme = themes.includes(storedTheme) ? storedTheme : 'dark';
  const dark = theme === 'dark' || (theme !== 'light' && matchMedia('(prefers-color-scheme: dark)').matches);
  document.documentElement.dataset.skin = skin;
  document.documentElement.dataset.theme = dark ? 'dark' : 'light';
})();
