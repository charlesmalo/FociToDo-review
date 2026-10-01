import http from 'k6/http';

export const BASE = __ENV.BASE_URL || 'http://web:8080/api';
const JSON_HEADERS = { 'Content-Type': 'application/json' };

export function createTodo(title) {
  const response = http.post(`${BASE}/todos`, JSON.stringify({ title }), { headers: JSON_HEADERS });
  if (response.status !== 201) throw new Error(`setup create failed: ${response.status}`);
  return response.json();
}

export function patch(id, version, body) {
  return http.patch(`${BASE}/todos/${id}`, JSON.stringify(body), {
    headers: { ...JSON_HEADERS, 'If-Match': `"${version}"` },
    tags: { name: 'PATCH /todos/:id' },
  });
}

export const jsonHeaders = JSON_HEADERS;
