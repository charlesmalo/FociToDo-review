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
  const todo = createTodo(`mixed-${__VU}-${__ITER}`);
  const list = http.get(`${BASE}/todos?sort=dueDate&order=asc`, { tags: { name: 'GET /todos' } });
  const edited = patch(todo.id, 1, { dueDate: '2030-01-01' });
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
