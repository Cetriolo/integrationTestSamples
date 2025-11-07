import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: 10 },  // Ramp up to 10 users
    { duration: '1m', target: 10 },   // Stay at 10 users
    { duration: '30s', target: 50 },  // Ramp up to 50 users
    { duration: '1m', target: 50 },   // Stay at 50 users
    { duration: '30s', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    http_req_failed: ['rate<0.1'],    // Error rate should be less than 10%
    errors: ['rate<0.1'],
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:8080';

export default function () {
  // Health check test
  group('Health Checks', function () {
    const healthRes = http.get(`${BASE_URL}/health`);
    check(healthRes, {
      'health status is 200': (r) => r.status === 200,
      'health response time < 200ms': (r) => r.timings.duration < 200,
      'health status is healthy': (r) => {
        try {
          return JSON.parse(r.body).status === 'healthy';
        } catch (e) {
          return false;
        }
      },
    }) || errorRate.add(1);

    const readyRes = http.get(`${BASE_URL}/ready`);
    check(readyRes, {
      'readiness status is 200': (r) => r.status === 200,
      'service is ready': (r) => {
        try {
          return JSON.parse(r.body).ready === true;
        } catch (e) {
          return false;
        }
      },
    }) || errorRate.add(1);
  });

  sleep(1);

  // User CRUD operations
  group('User Operations', function () {
    // Get all users
    const getUsersRes = http.get(`${BASE_URL}/api/users`);
    check(getUsersRes, {
      'get users status is 200': (r) => r.status === 200,
      'get users returns array': (r) => {
        try {
          return Array.isArray(JSON.parse(r.body));
        } catch (e) {
          return false;
        }
      },
    }) || errorRate.add(1);

    // Create user
    const newUser = JSON.stringify({
      name: `Load Test User ${Date.now()}`,
      email: `test-${Date.now()}@example.com`,
    });

    const createUserRes = http.post(`${BASE_URL}/api/users`, newUser, {
      headers: { 'Content-Type': 'application/json' },
    });

    const userId = check(createUserRes, {
      'create user status is 201': (r) => r.status === 201,
      'user has id': (r) => {
        try {
          return JSON.parse(r.body).id !== undefined;
        } catch (e) {
          return false;
        }
      },
    }) ? JSON.parse(createUserRes.body).id : null;

    if (userId) {
      // Get single user
      const getUserRes = http.get(`${BASE_URL}/api/users/${userId}`);
      check(getUserRes, {
        'get single user status is 200': (r) => r.status === 200,
      }) || errorRate.add(1);

      // Update user
      const updateData = JSON.stringify({
        name: `Updated User ${Date.now()}`,
      });

      const updateRes = http.put(`${BASE_URL}/api/users/${userId}`, updateData, {
        headers: { 'Content-Type': 'application/json' },
      });

      check(updateRes, {
        'update user status is 200': (r) => r.status === 200,
      }) || errorRate.add(1);

      // Delete user
      const deleteRes = http.del(`${BASE_URL}/api/users/${userId}`);
      check(deleteRes, {
        'delete user status is 204': (r) => r.status === 204,
      }) || errorRate.add(1);
    }
  });

  sleep(1);

  // Product operations
  group('Product Operations', function () {
    const getProductsRes = http.get(`${BASE_URL}/api/products`);
    check(getProductsRes, {
      'get products status is 200': (r) => r.status === 200,
      'products have required fields': (r) => {
        try {
          const products = JSON.parse(r.body);
          if (products.length > 0) {
            const product = products[0];
            return (
              product.id !== undefined &&
              product.name !== undefined &&
              product.price !== undefined &&
              product.stock !== undefined
            );
          }
          return true;
        } catch (e) {
          return false;
        }
      },
    }) || errorRate.add(1);

    // Create product
    const newProduct = JSON.stringify({
      name: `Load Test Product ${Date.now()}`,
      price: 99.99,
      stock: 100,
    });

    const createProductRes = http.post(`${BASE_URL}/api/products`, newProduct, {
      headers: { 'Content-Type': 'application/json' },
    });

    check(createProductRes, {
      'create product status is 201': (r) => r.status === 201,
    }) || errorRate.add(1);
  });

  sleep(1);

  // Error handling tests
  group('Error Handling', function () {
    const notFoundRes = http.get(`${BASE_URL}/api/users/99999`);
    check(notFoundRes, {
      'not found returns 404': (r) => r.status === 404,
    });

    const errorRes = http.get(`${BASE_URL}/api/error`);
    check(errorRes, {
      'error endpoint returns 500': (r) => r.status === 500,
    });
  });

  sleep(1);
}

// Smoke test configuration (export separately)
export const smokeTestOptions = {
  vus: 1,
  duration: '30s',
  thresholds: {
    http_req_duration: ['p(99)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};

// Load test configuration
export const loadTestOptions = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '5m', target: 200 },
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(99)<1500'],
    http_req_failed: ['rate<0.05'],
  },
};

// Stress test configuration
export const stressTestOptions = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '5m', target: 200 },
    { duration: '2m', target: 300 },
    { duration: '5m', target: 300 },
    { duration: '2m', target: 400 },
    { duration: '5m', target: 400 },
    { duration: '10m', target: 0 },
  ],
};