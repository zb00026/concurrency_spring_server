// k6 load test — the industry-standard tool for this scale.
// Install:  https://grafana.com/docs/k6/latest/set-up/install-k6/
// Run:      k6 run loadtest/k6.js
// Or with parameters: k6 run -e RPS=5000 -e VUS=10000 loadtest/k6.js

import http from 'k6/http';
import { check, sleep } from 'k6';

const RPS = Number(__ENV.RPS || 5000);
const VUS = Number(__ENV.VUS || 10000);
const BASE = __ENV.BASE_URL || 'http://localhost:8080';

export const options = {
  vus: VUS,
  // 5k RPS steady state, reached via a ramp so the JVM can warm up:
  // warm-up -> ramp to target -> sustain -> ramp down
  stages: [
    { duration: '2m', target: Math.min(VUS, 1000) },   // warm-up
    { duration: '3m', target: VUS },                   // ramp to full load
    { duration: '10m', target: VUS },                  // sustain (peak)
    { duration: '2m', target: 0 },                     // ramp down
  ],
  rps: RPS,
  thresholds: {
    // Fail the test if these are violated:
    http_req_failed: ['rate<0.01'],       // <1% errors
    http_req_duration: ['p(95)<200'],     // p95 under 200ms
    http_req_duration: ['p(99)<500'],     // p99 under 500ms
  },
};

export function setup() {
  // Seed one user so the read endpoint has data
  const res = http.post(`${BASE}/api/v1/users`,
    JSON.stringify({ name: 'Load Test', email: 'load@test.local' }),
    { headers: { 'Content-Type': 'application/json' } });
  check(res, { 'seed user created': (r) => r.status === 201 });
}

export default function () {
  // 90% cached reads (the realistic hot path), 10% writes
  const res = Math.random() < 0.9
    ? http.get(`${BASE}/api/v1/users/1`)
    : http.post(`${BASE}/api/v1/users`,
        JSON.stringify({ name: `u${__VU}`, email: `u${__VU}-${__ITER}@t.local` }),
        { headers: { 'Content-Type': 'application/json' } });

  check(res, {
    'status is 2xx': (r) => r.status >= 200 && r.status < 300,
  });
}
