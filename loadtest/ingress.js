import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE = __ENV.BASE || 'http://host.docker.internal:18081';
const params = { headers: { Host: 'staging.attendance.local' } };

export const options = {
  stages: [
    { duration: '30s', target: 50 },
    { duration: '2m', target: 200 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<2000'],
  },
};

export default function () {
  const r1 = http.get(BASE + '/', params);
  check(r1, { 'index 200': (r) => r.status === 200 });
  const r2 = http.get(BASE + '/checkin.html', params);
  check(r2, { 'checkin 200': (r) => r.status === 200 });
  sleep(0.1);
}