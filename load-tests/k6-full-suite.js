import http from 'k6/http';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';

/**
 * Daily Rashan — full load benchmark
 * Target: 500 concurrent customers browsing + ordering patterns
 *
 * Run:
 *   k6 run load-tests/k6-full-suite.js
 *   API_URL=https://api.staging.dhrigro.com k6 run load-tests/k6-full-suite.js
 */

const BASE = __ENV.API_URL || 'http://localhost:3000';
const API = `${BASE}/api/v1`;

export const options = {
  scenarios: {
    customers: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 100 },
        { duration: '3m', target: 500 },
        { duration: '2m', target: 500 },
        { duration: '1m', target: 0 },
      ],
      gracefulRampDown: '30s',
    },
    admins: {
      executor: 'constant-vus',
      vus: 20,
      duration: '5m',
      startTime: '1m',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<800', 'p(99)<1500'],
    http_req_failed: ['rate<0.02'],
    checks: ['rate>0.95'],
  },
};

const products = new SharedArray('products', function () {
  const res = http.get(`${API}/products?limit=20`);
  if (res.status !== 200) return [{ id: 'fallback' }];
  const data = JSON.parse(res.body).data || [];
  return data.length ? data : [{ id: 'fallback' }];
});

export default function () {
  const home = http.get(`${API}/home`);
  check(home, { 'home 200': (r) => r.status === 200 });

  const product = products[Math.floor(Math.random() * products.length)];
  if (product.id !== 'fallback') {
    const detail = http.get(`${API}/products/${product.id}`);
    check(detail, { 'product detail 200': (r) => r.status === 200 });
  }

  const search = http.get(`${API}/products?search=milk&limit=10`);
  check(search, { 'search 200': (r) => r.status === 200 });

  sleep(Math.random() * 2 + 0.5);
}

export function handleSummary(data) {
  const p95 = data.metrics.http_req_duration?.values?.['p(95)'] ?? 0;
  const failRate = data.metrics.http_req_failed?.values?.rate ?? 0;
  const rps = data.metrics.http_reqs?.values?.rate ?? 0;

  const report = {
    generatedAt: new Date().toISOString(),
    p95LatencyMs: Math.round(p95),
    failRate: Math.round(failRate * 10000) / 100,
    throughputRps: Math.round(rps * 100) / 100,
    thresholdsPassed: !data.root_group?.checks?.some?.((c) => c.fails > 0),
  };

  return {
    stdout: JSON.stringify(report, null, 2),
    'load-tests/reports/k6-benchmark.json': JSON.stringify(report, null, 2),
  };
}
