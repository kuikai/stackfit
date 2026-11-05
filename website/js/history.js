import { emptyState } from './empty_state.js';

const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const dayMs = 86400000;

export function renderHistory(sessions, now = new Date(), onDelete) {
  const list = document.querySelector('#history-list');
  list.replaceChildren();
  const groups = groupByWeek(sessions, now);
  if (groups.length > 0) {
    renderStats(historyStats(sessions, now));
  } else {
    document.querySelector('#history-stats').replaceChildren();
  }
  if (groups.length === 0) {
    list.append(emptyState({
      icon: 'calendar',
      title: 'No sessions yet',
      text: 'Finish a workout here or on your phone and it shows up here.',
    }));
    return;
  }
  for (const group of groups) {
    list.append(groupLabel(group.label, group.sessions.length));
    for (const session of group.sessions) {
      list.append(historyRow(session, now, onDelete));
    }
  }
}

export function groupLabel(text, count) {
  const label = document.createElement('h3');
  label.className = 'group-label';
  label.textContent = text;
  const number = document.createElement('span');
  number.textContent = String(count);
  label.append(number);
  return label;
}

/// Sessions this week (from Monday), their minutes, and days in a row trained.
/// The streak still counts when today has no session yet but yesterday does.
export function historyStats(sessions, now = new Date()) {
  const weekStart = startOfWeek(now).getTime();
  const thisWeek = sessions.filter((session) => sessionTime(session) >= weekStart);
  const seconds = thisWeek.reduce((sum, session) => sum + (session.durationSeconds || 0), 0);
  return {
    weekSessions: thisWeek.length,
    weekMinutes: Math.round(seconds / 60),
    dayStreak: dayStreak(sessions, now),
  };
}

export function groupByWeek(sessions, now = new Date()) {
  const ordered = sessions
    .filter((session) => !Number.isNaN(sessionTime(session)))
    .sort((left, right) => sessionTime(right) - sessionTime(left));
  const thisWeek = startOfWeek(now).getTime();
  const groups = [];
  for (const session of ordered) {
    const weekStart = startOfWeek(new Date(sessionTime(session)));
    const label = weekLabel(weekStart.getTime(), thisWeek);
    const last = groups[groups.length - 1];
    if (last?.label === label) {
      last.sessions.push(session);
    } else {
      groups.push({ label, sessions: [session] });
    }
  }
  return groups;
}

export function shortDay(iso, now = new Date()) {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) {
    return '';
  }
  const daysAgo = Math.round((startOfDay(now) - startOfDay(date)) / dayMs);
  if (daysAgo === 0) {
    return 'Today';
  }
  if (daysAgo === 1) {
    return 'Yesterday';
  }
  return `${dayNames[date.getDay()]} ${date.getDate()} ${monthNames[date.getMonth()]}`;
}

export function shortMinutes(totalSeconds) {
  const seconds = Math.max(0, Math.round(totalSeconds || 0));
  if (seconds < 60) {
    return `${seconds}s`;
  }
  return `${Math.round(seconds / 60)} min`;
}

export function startOfWeek(date) {
  const start = new Date(startOfDay(date));
  const sinceMonday = (start.getDay() + 6) % 7;
  start.setDate(start.getDate() - sinceMonday);
  return start;
}

function dayStreak(sessions, now) {
  const days = new Set(sessions.map((session) => startOfDay(new Date(sessionTime(session)))));
  let day = new Date(startOfDay(now));
  if (!days.has(day.getTime())) {
    day.setDate(day.getDate() - 1);
  }
  let streak = 0;
  while (days.has(day.getTime())) {
    streak += 1;
    day.setDate(day.getDate() - 1);
  }
  return streak;
}

function weekLabel(weekStart, thisWeek) {
  if (weekStart === thisWeek) {
    return 'This week';
  }
  const lastWeek = new Date(thisWeek);
  lastWeek.setDate(lastWeek.getDate() - 7);
  if (weekStart === lastWeek.getTime()) {
    return 'Last week';
  }
  const start = new Date(weekStart);
  return `Week of ${start.getDate()} ${monthNames[start.getMonth()]}`;
}

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
}

function sessionTime(session) {
  return Date.parse(session.completedAt);
}

function renderStats(stats) {
  const box = document.querySelector('#history-stats');
  box.replaceChildren(
    statTile(String(stats.weekSessions), stats.weekSessions === 1 ? 'session this week' : 'sessions this week'),
    statTile(String(stats.weekMinutes), 'minutes this week'),
    statTile(String(stats.dayStreak), 'day streak'),
  );
}

function statTile(value, label) {
  const tile = document.createElement('div');
  tile.className = 'stat';
  const number = document.createElement('strong');
  number.textContent = value;
  const text = document.createElement('span');
  text.textContent = label;
  tile.append(number, text);
  return tile;
}

export function historyRow(session, now = new Date(), onDelete) {
  const row = document.createElement('article');
  row.className = 'history-row';
  const text = document.createElement('div');
  const title = document.createElement('h4');
  title.textContent = session.workoutName;
  const meta = document.createElement('p');
  meta.className = 'meta';
  const count = session.totalExercises || 0;
  meta.textContent = `${shortDay(session.completedAt, now)} · ${count === 1 ? '1 exercise' : `${count} exercises`}`;
  text.append(title, meta);
  const duration = document.createElement('span');
  duration.className = 'history-duration';
  duration.textContent = shortMinutes(session.durationSeconds);
  row.append(text, duration);
  if (onDelete) {
    row.append(deleteButton(session, onDelete));
  }
  return row;
}

function deleteButton(session, onDelete) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'text danger-text history-delete';
  button.textContent = 'Delete';
  button.addEventListener('click', () => onDelete(session));
  return button;
}

/// Removes one finished workout and records the deletion so sync keeps it gone.
export async function deleteHistorySession(app, session) {
  const name = session.workoutName || 'this session';
  if (!window.confirm(`Delete ${name} from history?`)) {
    return;
  }
  const snapshot = app.cloneSnapshot(app.account.snapshot);
  snapshot.sessions = snapshot.sessions.filter((item) => item.id !== session.id);
  snapshot.deletedSessions = snapshot.deletedSessions.filter((item) => item.id !== session.id);
  snapshot.deletedSessions.push({
    id: session.id,
    deletedAt: new Date().toISOString(),
  });
  await app.persist(snapshot, 'Deleted. The app drops it the next time it syncs.');
}
