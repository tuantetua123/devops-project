import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE = __ENV.BASE_URL;
const HOST = __ENV.HOST_HEADER;

http.setResponseCallback(http.expectedStatuses(400));

export const options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '2m', target: 80 },
    { duration: '30s', target: 0 },
  ],
};

export default function () {
  const body = JSON.stringify({ token: 'x.y.z', student_id: '1', student_name: 'load' });
  const res = http.post(BASE + '/api/checkin', body, {
    headers: { 'Content-Type': 'application/json', Host: HOST },
  });
  check(res, { 'status 400 (token sai, api va qr deu xu ly)': (r) => r.status === 400 });
  sleep(0.05);
}
