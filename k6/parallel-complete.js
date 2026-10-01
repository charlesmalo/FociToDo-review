import http from 'k6/http';
import { check } from 'k6';
import { BASE, createTodo } from './common.js';

http.setResponseCallback(http.expectedStatuses(200, 201));
export const options = { vus: 40, iterations: 400, thresholds: { checks: ['rate==1'] } };

export function setup() {
  return { ids: Array.from({ length: 10 }, (_, i) => createTodo(`complete-${i}`).id) };
}

export default function ({ ids }) {
  const id = ids[__ITER % ids.length];
  check(http.post(`${BASE}/todos/${id}/complete`, null, { tags: { name: 'POST complete' } }), {
    'complete is 200': (r) => r.status === 200,
  });
}
