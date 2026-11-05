import assert from 'node:assert/strict';
import { test } from 'node:test';

import { loadSkin, loadTheme, resolveTheme } from '../../website/js/appearance.js';

test('an unknown saved skin falls back to Night', () => {
  const store = new Map([['stackfit.skin', 'mint']]);
  globalThis.localStorage = {
    getItem: (key) => store.get(key) ?? null,
    setItem: (key, value) => store.set(key, value),
  };
  assert.equal(loadSkin(), 'night');
  assert.equal(loadTheme(), 'dark');
});

test('Night and a saved Iron skin both load', () => {
  const store = new Map([['stackfit.skin', 'iron'], ['stackfit.theme', 'system']]);
  globalThis.localStorage = {
    getItem: (key) => store.get(key) ?? null,
    setItem: (key, value) => store.set(key, value),
  };
  assert.equal(loadSkin(), 'iron');
  assert.equal(loadTheme(), 'system');
});

test('system brightness follows the computer', () => {
  assert.equal(resolveTheme('dark', false), 'dark');
  assert.equal(resolveTheme('light', true), 'light');
  assert.equal(resolveTheme('system', true), 'dark');
  assert.equal(resolveTheme('system', false), 'light');
});
