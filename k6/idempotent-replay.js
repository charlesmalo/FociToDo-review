import http from 'k6/http';
import { check } from 'k6';
import { BASE, jsonHeaders } from './common.js';

http.setResponseCallback(http.expectedStatuses(201));
export const options = { vus: 40, iterations: 800, thresholds: { checks: ['rate==1'] } };

export default function () {
  const n = __ITER % 20;
  const response = http.post(`${BASE}/todos`, JSON.stringify({ title: `replay-${n}` }), {
    headers: { ...jsonHeaders, 'Idempotency-Key': `stress-key-${n}` },
    tags: { name: 'POST /todos (keyed)' },
  });
  check(response, { 'keyed create is 201': (r) => r.status === 201 });
}
