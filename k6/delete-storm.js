import http from 'k6/http';
import { check } from 'k6';
import { Counter } from 'k6/metrics';
import { BASE, createTodo } from './common.js';

http.setResponseCallback(http.expectedStatuses(201, 204, 404));
export const options = { vus: 30, iterations: 600, thresholds: { checks: ['rate==1'] } };
const deleted = new Counter('deleted');

export function setup() {
  return { ids: Array.from({ length: 20 }, (_, i) => createTodo(`delete-${i}`).id) };
}

export default function ({ ids }) {
  const id = ids[__ITER % ids.length];
  const response = http.del(`${BASE}/todos/${id}`, null, {
    headers: { 'If-Match': '"1"' },
    tags: { name: 'DELETE /todos/:id' },
  });
  check(response, { 'DELETE is 204 or 404': (r) => r.status === 204 || r.status === 404 });
  if (response.status === 204) deleted.add(1);
}
