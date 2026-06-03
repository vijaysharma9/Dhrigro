import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 30,
  duration: '1m',
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.05'],
  },
};

const BASE = __ENV.API_URL || 'http://localhost:3000';

export default function () {
  const res = http.get(`${BASE}/api/v1/home`);
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(1);
}
