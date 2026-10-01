// Usage: node invariants.mjs <scenario> <summary.json> <apiBase>
import { readFileSync } from 'node:fs';

const [scenario, summaryPath, base] = process.argv.slice(2);
const summary = JSON.parse(readFileSync(summaryPath, 'utf8'));
const counter = (name) => summary.metrics[name]?.count ?? 0;
const todos = await (await fetch(`${base}/todos`)).json();

const results = [];
const expect = (label, actual, expected) => results.push({ label, actual, expected, ok: actual === expected });

if (scenario === 'race-patch') {
  const raced = todos.filter((todo) => /^(race-\d|edit )/.test(todo.title));
  const versionGain = raced.reduce((sum, todo) => sum + (todo.version - 1), 0);
  expect('Σ(version − 1) equals successful PATCHes (no lost or phantom updates)', versionGain, counter('successful_patches'));
}
if (scenario === 'parallel-complete') {
  const done = todos.filter((todo) => todo.title.startsWith('complete-'));
  expect('every todo completed', done.every((todo) => todo.isCompleted), true);
  expect('each todo bumped exactly once', done.every((todo) => todo.version === 2), true);
}
if (scenario === 'delete-storm') {
  expect('exactly one successful delete per todo', counter('deleted'), 20);
  expect('no deleted todo remains', todos.filter((todo) => todo.title.startsWith('delete-')).length, 0);
}
if (scenario === 'idempotent-replay') {
  expect('one row per idempotency key', todos.filter((todo) => todo.title.startsWith('replay-')).length, 20);
}
if (scenario === 'mixed-load') {
  expect('no mixed-load todo left behind', todos.filter((todo) => todo.title.startsWith('mixed-')).length, 0);
}

for (const r of results) console.log(`${r.ok ? 'PASS' : 'FAIL'} ${r.label} (actual ${r.actual}, expected ${r.expected})`);
process.exit(results.every((r) => r.ok) ? 0 : 1);
