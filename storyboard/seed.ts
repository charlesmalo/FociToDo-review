import type { APIRequestContext } from '@playwright/test';

export const HOUR = 3_600_000;
export const DAY = 24 * HOUR;

/** Returns the instant `offsetMs` away from now, as an ISO 8601 UTC string (a `dueAt` value). */
export function isoIn(offsetMs: number): string {
  return new Date(Date.now() + offsetMs).toISOString();
}

/**
 * The deadline text the app should show for an instant in a timezone: "Due <date>, <time>",
 * medium date and short time in en-US. Whitespace is normalised (newer ICU puts a narrow
 * no-break space before AM/PM) so it compares equal to what Playwright reads from the page.
 */
export function deadlineText(iso: string, timeZone: string): string {
  const text = new Intl.DateTimeFormat('en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone,
  }).format(new Date(iso));
  return `Due ${text}`.replace(/\s+/g, ' ');
}

interface SeededTodo {
  id: string;
  version: number;
  [key: string]: unknown;
}

/** Seeds one todo through the black-box API (POST /api/todos) and returns its JSON body. */
export async function createTodo(
  request: APIRequestContext,
  body: Record<string, unknown>,
): Promise<SeededTodo> {
  const response = await request.post('/api/todos', { data: body });
  if (!response.ok()) {
    throw new Error(`seed: POST /api/todos failed with ${response.status()}: ${await response.text()}`);
  }
  return response.json();
}
