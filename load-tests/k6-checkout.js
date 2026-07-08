import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE = __ENV.API_URL || 'http://localhost:3000';
const API = `${BASE}/api/v1`;

export const options = {
  vus: 50,
  duration: '3m',
  thresholds: {
    http_req_duration: ['p(95)<1200'],
    http_req_failed: ['rate<0.05'],
  },
};

export function setup() {
  const phone = `9${Date.now().toString().slice(-9)}`;
  const reg = http.post(
    `${API}/auth/register`,
    JSON.stringify({
      phone,
      password: 'Load@123456',
      name: 'Load Test User',
    }),
    { headers: { 'Content-Type': 'application/json' } },
  );
  const body = JSON.parse(reg.body);
  const token = body.accessToken;

  const products = http.get(`${API}/products?limit=5`);
  const productId = JSON.parse(products.body).data?.[0]?.id;

  const address = http.post(
    `${API}/addresses`,
    JSON.stringify({
      fullName: 'Load User',
      phone,
      addressLine1: 'Load Test Address',
      city: 'Delhi',
      state: 'Delhi',
      pincode: '110001',
    }),
    {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
    },
  );
  const addressId = JSON.parse(address.body).id;

  return { token, productId, addressId };
}

export default function (data) {
  const headers = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${data.token}`,
  };

  http.post(
    `${API}/cart/items`,
    JSON.stringify({ productId: data.productId, quantity: 1 }),
    { headers },
  );

  const cart = http.get(`${API}/cart`, { headers });
  check(cart, { 'cart ok': (r) => r.status === 200 });

  sleep(1);
}
