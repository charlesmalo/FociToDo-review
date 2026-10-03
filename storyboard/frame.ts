import { appendFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import type { Page } from '@playwright/test';

const OUT = process.env.OUT ?? '/out';

/** Captures one storyboard frame. Call it only after the step's assertions have passed. */
export async function frame(
  page: Page,
  journey: string,
  step: number,
  caption: string,
  wireframe: string,
): Promise<void> {
  mkdirSync(join(OUT, 'frames'), { recursive: true });
  const file = `${journey}-${String(step).padStart(2, '0')}.png`;
  await page.screenshot({ path: join(OUT, 'frames', file), animations: 'disabled' });
  appendFileSync(
    join(OUT, 'frames.jsonl'),
    `${JSON.stringify({ journey, step, caption, wireframe, file })}\n`,
  );
}
