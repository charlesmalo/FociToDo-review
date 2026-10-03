// Builds storyboard.md: each frame beside the wireframe of the screen it should match.
import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const OUT = process.env.OUT ?? '/out';
const DIAGRAMS = process.env.APP_DIAGRAMS ?? '/app-diagrams';
const SHA = process.env.APP_SHA ?? 'unknown';

const frames = readFileSync(join(OUT, 'frames.jsonl'), 'utf8')
  .split('\n')
  .filter(Boolean)
  .map((line) => JSON.parse(line));
const wireframes = JSON.parse(readFileSync(join(DIAGRAMS, 'manifest.json'), 'utf8'))
  .diagrams.filter((d) => d.id.startsWith('ui/'));
const known = new Map(wireframes.map((d) => [d.id, d]));

const problems = [];
for (const f of frames) if (!known.has(f.wireframe)) problems.push(`frame ${f.file} names unknown wireframe ${f.wireframe}`);
for (const d of wireframes) if (!frames.some((f) => f.wireframe === d.id)) problems.push(`wireframe ${d.id} has no frame`);
if (problems.length > 0) {
  console.error(`storyboard: ${problems.join('\n')}`);
  process.exit(1);
}

mkdirSync(join(OUT, 'wireframes'), { recursive: true });
for (const d of wireframes) {
  const source = join(DIAGRAMS, 'ui', `${d.id.slice(3)}.svg`);
  if (!existsSync(source)) { console.error(`storyboard: missing ${source}`); process.exit(1); }
  copyFileSync(source, join(OUT, 'wireframes', `${d.id.slice(3)}.svg`));
}

// Escapes a caption/heading for use as an HTML alt attribute (double quote) and, since the
// <img> itself sits inside a Markdown table cell, for the pipe too — captions are free text
// from journeys/*.spec.ts, so any of these characters can appear.
const forAlt = (s) => s.replaceAll('"', '&quot;').replaceAll('|', '&#124;');
const forCell = (s) => s.replaceAll('|', '\\|');

const journeys = [...new Set(frames.map((f) => f.journey))];
const lines = [`# Storyboard — FociToDo @ ${SHA}`, '', `${frames.length} frames across ${journeys.length} journeys; every wireframe in the app's docs/ui.md is paired with at least one frame. Each frame was captured only after the step's assertions passed.`, ''];
for (const journey of journeys) {
  lines.push(`## ${journey}`, '', '| # | Wireframe | Running app | What happened |', '|---|---|---|---|');
  for (const f of frames.filter((x) => x.journey === journey)) {
    const w = known.get(f.wireframe);
    lines.push(`| ${f.step} | <img src="wireframes/${f.wireframe.slice(3)}.svg" width="360" alt="${forAlt(w.heading)}"> | <img src="frames/${f.file}" width="420" alt="${forAlt(f.caption)}"> | ${forCell(f.caption)} |`);
  }
  lines.push('');
}
writeFileSync(join(OUT, 'storyboard.md'), lines.join('\n'));
console.log(`storyboard: ${frames.length} frames, ${journeys.length} journeys, ${wireframes.length} wireframes paired`);
