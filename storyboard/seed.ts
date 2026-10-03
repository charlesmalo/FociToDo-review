import type { APIRequestContext } from '@playwright/test';

/** Returns the UTC calendar date `offsetDays` away from now, as `YYYY-MM-DD`. */
export function utcDate(offsetDays: number): string {
  return new Date(Date.now() + offsetDays * 86_400_000).toISOString().slice(0, 10);
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
