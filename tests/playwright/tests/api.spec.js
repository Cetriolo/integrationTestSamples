// tests/api.spec.js
import { test, expect } from '@playwright/test';

const BASE_URL = process.env.API_URL || 'http://localhost:8080';

test.describe('API Health Checks', () => {
  test('health endpoint returns healthy status', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/health`);
    expect(response.ok()).toBeTruthy();
    expect(response.status()).toBe(200);

    const data = await response.json();
    expect(data.status).toBe('healthy');
    expect(data).toHaveProperty('version');
    expect(data).toHaveProperty('timestamp');
  });

  test('readiness endpoint returns ready status', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/ready`);
    expect(response.ok()).toBeTruthy();

    const data = await response.json();
    expect(data.ready).toBe(true);
    expect(data.checks).toHaveProperty('database');
    expect(data.checks).toHaveProperty('cache');
  });

  test('version endpoint returns version info', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/version`);
    expect(response.ok()).toBeTruthy();

    const data = await response.json();
    expect(data).toHaveProperty('version');
    expect(data).toHaveProperty('build_date');
    expect(data).toHaveProperty('go_version');
  });

  test('health check response time is acceptable', async ({ request }) => {
    const start = Date.now();
    await request.get(`${BASE_URL}/health`);
    const duration = Date.now() - start;

    expect(duration).toBeLessThan(500);
  });
});

test.describe('User Management API', () => {
  let createdUserId;

  test('should get all users', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/api/users`);
    expect(response.ok()).toBeTruthy();

    const users = await response.json();
    expect(Array.isArray(users)).toBeTruthy();

    if (users.length > 0) {
      expect(users[0]).toHaveProperty('id');
      expect(users[0]).toHaveProperty('name');
      expect(users[0]).toHaveProperty('email');
      expect(users[0]).toHaveProperty('created_at');
    }
  });

  test('should create a new user', async ({ request }) => {
    const newUser = {
      name: 'Playwright Test User',
      email: `playwright-${Date.now()}@example.com`,
    };

    const response = await request.post(`${BASE_URL}/api/users`, {
      data: newUser,
    });

    expect(response.status()).toBe(201);

    const user = await response.json();
    expect(user).toHaveProperty('id');
    expect(user.name).toBe(newUser.name);
    expect(user.email).toBe(newUser.email);
    expect(user).toHaveProperty('created_at');

    createdUserId = user.id;
  });

  test('should get a single user', async ({ request }) => {
    // First create a user
    const newUser = {
      name: 'Test User for Get',
      email: `get-test-${Date.now()}@example.com`,
    };

    const createResponse = await request.post(`${BASE_URL}/api/users`, {
      data: newUser,
    });
    const createdUser = await createResponse.json();

    // Now get that user
    const response = await request.get(`${BASE_URL}/api/users/${createdUser.id}`);
    expect(response.ok()).toBeTruthy();

    const user = await response.json();
    expect(user.id).toBe(createdUser.id);
    expect(user.name).toBe(newUser.name);
    expect(user.email).toBe(newUser.email);
  });

  test('should update a user', async ({ request }) => {
    // Create a user first
    const newUser = {
      name: 'User to Update',
      email: `update-${Date.now()}@example.com`,
    };

    const createResponse = await request.post(`${BASE_URL}/api/users`, {
      data: newUser,
    });
    const createdUser = await createResponse.json();

    // Update the user
    const updateData = {
      name: 'Updated User Name',
    };

    const response = await request.put(`${BASE_URL}/api/users/${createdUser.id}`, {
      data: updateData,
    });

    expect(response.ok()).toBeTruthy();

    const updatedUser = await response.json();
    expect(updatedUser.name).toBe(updateData.name);
    expect(updatedUser.id).toBe(createdUser.id);
  });

  test('should delete a user', async ({ request }) => {
    // Create a user first
    const newUser = {
      name: 'User to Delete',
      email: `delete-${Date.now()}@example.com`,
    };

    const createResponse = await request.post(`${BASE_URL}/api/users`, {
      data: newUser,
    });
    const createdUser = await createResponse.json();

    // Delete the user
    const response = await request.delete(`${BASE_URL}/api/users/${createdUser.id}`);
    expect(response.status()).toBe(204);

    // Verify user is deleted
    const getResponse = await request.get(`${BASE_URL}/api/users/${createdUser.id}`);
    expect(getResponse.status()).toBe(404);
  });

  test('should return 404 for non-existent user', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/api/users/99999`);
    expect(response.status()).toBe(404);

    const error = await response.json();
    expect(error).toHaveProperty('error');
    expect(error).toHaveProperty('code');
    expect(error).toHaveProperty('message');
  });

  test('should validate required fields when creating user', async ({ request }) => {
    const invalidUser = {
      name: '',
      email: '',
    };

    const response = await request.post(`${BASE_URL}/api/users`, {
      data: invalidUser,
    });

    expect(response.status()).toBe(400);
  });
});

test.describe('Product Management API', () => {
  test('should get all products', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/api/products`);
    expect(response.ok()).toBeTruthy();

    const products = await response.json();
    expect(Array.isArray(products)).toBeTruthy();

    if (products.length > 0) {
      expect(products[0]).toHaveProperty('id');
      expect(products[0]).toHaveProperty('name');
      expect(products[0]).toHaveProperty('price');
      expect(products[0]).toHaveProperty('stock');
    }
  });

  test('should create a new product', async ({ request }) => {
    const newProduct = {
      name: 'Playwright Test Product',
      price: 149.99,
      stock: 50,
    };

    const response = await request.post(`${BASE_URL}/api/products`, {
      data: newProduct,
    });

    expect(response.status()).toBe(201);

    const product = await response.json();
    expect(product).toHaveProperty('id');
    expect(product.name).toBe(newProduct.name);
    expect(product.price).toBe(newProduct.price);
    expect(product.stock).toBe(newProduct.stock);
  });

  test('should get a single product', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/api/products/1`);

    if (response.ok()) {
      const product = await response.json();
      expect(product).toHaveProperty('id');
      expect(product).toHaveProperty('name');
      expect(product).toHaveProperty('price');
    }
  });

  test('should update a product', async ({ request }) => {
    // Create a product first
    const newProduct = {
      name: 'Product to Update',
      price: 99.99,
      stock: 10,
    };

    const createResponse = await request.post(`${BASE_URL}/api/products`, {
      data: newProduct,
    });
    const createdProduct = await createResponse.json();

    // Update the product
    const updateData = {
      name: 'Updated Product',
      price: 129.99,
      stock: 20,
    };

    const response = await request.put(`${BASE_URL}/api/products/${createdProduct.id}`, {
      data: updateData,
    });

    expect(response.ok()).toBeTruthy();

    const updatedProduct = await response.json();
    expect(updatedProduct.name).toBe(updateData.name);
    expect(updatedProduct.price).toBe(updateData.price);
    expect(updatedProduct.stock).toBe(updateData.stock);
  });

  test('should validate product price', async ({ request }) => {
    const invalidProduct = {
      name: 'Invalid Product',
      price: -10,
      stock: 5,
    };

    const response = await request.post(`${BASE_URL}/api/products`, {
      data: invalidProduct,
    });

    expect(response.status()).toBe(400);
  });
});

test.describe('Error Handling', () => {
  test('should handle 404 errors gracefully', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/api/nonexistent`);
    expect(response.status()).toBe(404);
  });

  test('should handle intentional errors', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/api/error`);
    expect(response.status()).toBe(500);

    const error = await response.json();
    expect(error).toHaveProperty('error');
    expect(error).toHaveProperty('code');
    expect(error).toHaveProperty('message');
  });

  test('should handle slow endpoint', async ({ request }) => {
    const start = Date.now();
    const response = await request.get(`${BASE_URL}/api/slow`);
    const duration = Date.now() - start;

    expect(response.ok()).toBeTruthy();
    expect(duration).toBeGreaterThanOrEqual(3000);

    const data = await response.json();
    expect(data.message).toContain('slow');
  });
});

test.describe('API Workflow Tests', () => {
  test('complete user lifecycle', async ({ request }) => {
    // 1. Create user
    const newUser = {
      name: 'Lifecycle Test User',
      email: `lifecycle-${Date.now()}@example.com`,
    };

    const createResponse = await request.post(`${BASE_URL}/api/users`, {
      data: newUser,
    });
    expect(createResponse.status()).toBe(201);
    const user = await createResponse.json();

    // 2. Read user
    const getResponse = await request.get(`${BASE_URL}/api/users/${user.id}`);
    expect(getResponse.ok()).toBeTruthy();

    // 3. Update user
    const updateResponse = await request.put(`${BASE_URL}/api/users/${user.id}`, {
      data: { name: 'Updated Lifecycle User' },
    });
    expect(updateResponse.ok()).toBeTruthy();

    // 4. Delete user
    const deleteResponse = await request.delete(`${BASE_URL}/api/users/${user.id}`);
    expect(deleteResponse.status()).toBe(204);

    // 5. Verify deletion
    const verifyResponse = await request.get(`${BASE_URL}/api/users/${user.id}`);
    expect(verifyResponse.status()).toBe(404);
  });
});