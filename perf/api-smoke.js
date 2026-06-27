// k6 load + soak script for DealDrop's hottest public endpoints, with explicit
// performance budgets asserted as thresholds (a regression past budget fails k6,
// which fails `scripts/load.sh`). Run via: scripts/load.sh  (needs k6 + a target)
//
// Stages model a ramp → sustained load → soak → ramp-down so resource leaks
// under sustained traffic surface as a creeping p95.
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errors = new Rate('business_errors');
const BASE = __ENV.LOAD_TARGET || 'http://localhost:3000';

export const options = {
  scenarios: {
    ramp_and_soak: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 20 }, // ramp
        { duration: '1m', target: 20 },  // sustained
        { duration: '2m', target: 20 },  // soak (leak detection)
        { duration: '20s', target: 0 },  // ramp down
      ],
      gracefulRampDown: '10s',
    },
  },
  // Performance BUDGETS — adjust deliberately in review, never silently.
  thresholds: {
    http_req_failed: ['rate<0.01'],          // <1% transport failures
    business_errors: ['rate<0.01'],          // <1% non-2xx business responses
    'http_req_duration{endpoint:feed}': ['p95<400'],
    'http_req_duration{endpoint:search}': ['p95<450'],
    'http_req_duration{endpoint:map}': ['p95<350'],
  },
};

function hit(path, endpoint) {
  const res = http.get(`${BASE}${path}`, { tags: { endpoint } });
  const ok = check(res, { 'status is 200': (r) => r.status === 200 });
  errors.add(!ok);
}

export default function () {
  hit('/v1/feed/home?limit=10', 'feed');
  hit('/v1/search?q=taco&limit=10', 'search');
  hit('/v1/listings/map-bounds?north=33.9&south=33.6&east=-84.2&west=-84.5', 'map');
  sleep(1);
}
