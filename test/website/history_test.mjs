import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  groupByWeek,
  historyStats,
  shortDay,
  shortMinutes,
  startOfWeek,
} from '../../website/js/history.js';

const now = new Date(2026, 9, 31, 19, 0);

function session(daysAgo, minutes, name = 'Push day') {
  const when = new Date(2026, 9, 31 - daysAgo, 18, 0);
  return { workoutName: name, completedAt: when.toISOString(), durationSeconds: minutes * 60 };
}

test('the week starts on Monday', () => {
  assert.equal(startOfWeek(now).getTime(), new Date(2026, 9, 26).getTime());
  assert.equal(startOfWeek(new Date(2026, 9, 26, 9)).getTime(), new Date(2026, 9, 26).getTime());
});

test('stats count this week and a day streak', () => {
  const sessions = [session(0, 25), session(1, 30), session(2, 20), session(5, 40), session(6, 15)];
  assert.deepEqual(historyStats(sessions, now), { weekSessions: 4, weekMinutes: 115, dayStreak: 3 });
});

test('the streak still counts before today is trained', () => {
  const sessions = [session(1, 20), session(2, 20)];
  assert.equal(historyStats(sessions, now).dayStreak, 2);
  assert.equal(historyStats([session(2, 20)], now).dayStreak, 0);
  assert.equal(historyStats([], now).dayStreak, 0);
});

test('sessions group by week, newest first', () => {
  const groups = groupByWeek([session(6, 10), session(0, 10), session(8, 10), session(20, 10)], now);
  assert.deepEqual(
    groups.map((group) => [group.label, group.sessions.length]),
    [['This week', 1], ['Last week', 2], ['Week of 5 Oct', 1]],
  );
});

test('short days and minutes read naturally', () => {
  assert.equal(shortDay(session(0, 1).completedAt, now), 'Today');
  assert.equal(shortDay(session(1, 1).completedAt, now), 'Yesterday');
  assert.equal(shortDay(session(5, 1).completedAt, now), 'Mon 26 Oct');
  assert.equal(shortMinutes(45), '45s');
  assert.equal(shortMinutes(1500), '25 min');
});
