const icons = {
  dumbbell: '<rect x="2" y="9" width="3" height="6" rx="1"/><rect x="5" y="6" width="4" height="12" rx="1.5"/><rect x="15" y="6" width="4" height="12" rx="1.5"/><rect x="19" y="9" width="3" height="6" rx="1"/><rect x="9" y="11" width="6" height="2" rx="1"/>',
  calendar: '<rect x="3" y="5" width="18" height="16" rx="3" fill="none" stroke="currentColor" stroke-width="2"/><rect x="3" y="5" width="18" height="5" rx="2"/><rect x="7" y="2" width="2" height="5" rx="1"/><rect x="15" y="2" width="2" height="5" rx="1"/><circle cx="8" cy="14" r="1.4"/><circle cx="12" cy="14" r="1.4"/><circle cx="16" cy="14" r="1.4"/><circle cx="8" cy="18" r="1.4"/>',
};

/// A friendly placeholder for an empty list: picture, title, one line, and
/// optional buttons. `actions` is a list of { label, style, onClick }.
export function emptyState({ icon, title, text, actions = [] }) {
  const box = document.createElement('div');
  box.className = 'empty-state';
  const picture = document.createElement('span');
  picture.className = 'empty-icon';
  picture.innerHTML = `<svg viewBox="0 0 24 24" width="32" height="32" fill="currentColor" aria-hidden="true">${icons[icon] || ''}</svg>`;
  const heading = document.createElement('h3');
  heading.textContent = title;
  const line = document.createElement('p');
  line.className = 'meta';
  line.textContent = text;
  box.append(picture, heading, line);
  if (actions.length > 0) {
    const row = document.createElement('div');
    row.className = 'button-row';
    for (const action of actions) {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = action.style || 'primary';
      button.textContent = action.label;
      button.addEventListener('click', action.onClick);
      row.append(button);
    }
    box.append(row);
  }
  return box;
}
