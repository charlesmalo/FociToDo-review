import http from 'k6/http';
import { check } from 'k6';
import { Counter } from 'k6/metrics';
import { BASE, createTodo, patch } from './common.js';

// 412 is an expected outcome of a lost race, not a failure.
http.setResponseCallback(http.expectedStatuses(200, 201, 412));
export const options = {
  vus: 50,
  duration: '30s',
  thresholds: { checks: ['rate==1'], http_req_failed: ['rate==0'] },
};
const successfulPatches = new Counter('successful_patches');

export function setup() {
  return { ids: Array.from({ length: 5 }, (_, i) => createTodo(`race-${i}`).id) };
}

export default function ({ ids }) {
  const id = ids[Math.floor(Math.random() * ids.length)];
  const current = http.get(`${BASE}/todos/${id}`, { tags: { name: 'GET /todos/:id' } });
  const response = patch(id, current.json('version'), { title: `edit ${__VU}-${__ITER}` });
  check(response, { 'PATCH is 200 or 412': (r) => r.status === 200 || r.status === 412 });
  if (response.status === 200) successfulPatches.add(1);
}
