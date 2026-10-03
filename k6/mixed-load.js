import http from 'k6/http';
import { check } from 'k6';
import { BASE, createTodo, jsonHeaders, patch } from './common.js';

http.setResponseCallback(http.expectedStatuses(200, 201, 204, 404, 412));
export const options = {
  stages: [
    { duration: '10s', target: 50 },
    { duration: '30s', target: 50 },
    { duration: '10s', target: 0 },
  ],
  thresholds: {
    'http_req_duration{name:GET /todos}': ['p(95)<250'],
    'http_req_failed': ['rate==0'],
    checks: ['rate==1'],
  },
};

export default function () {
  // An RFC 3339 instant with an offset, 30 days after this iteration starts.
  const dueAt = new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString().replace('Z', '+00:00');
  const todo = createTodo(`mixed-${__VU}-${__ITER}`);
  const list = http.get(`${BASE}/todos?sort=dueAt&order=asc`, { tags: { name: 'GET /todos' } });
  const edited = patch(todo.id, 1, { dueAt });
  const completed = http.post(`${BASE}/todos/${todo.id}/complete`, null, { tags: { name: 'POST complete' } });
  const removed = http.del(`${BASE}/todos/${todo.id}`, null, {
    headers: { ...jsonHeaders, 'If-Match': '"3"' },
    tags: { name: 'DELETE /todos/:id' },
  });
  check({ list, edited, completed, removed }, {
    'list 200': (r) => r.list.status === 200,
    'edit 200': (r) => r.edited.status === 200,
    'complete 200': (r) => r.completed.status === 200,
    'delete 204': (r) => r.removed.status === 204,
  });
}
