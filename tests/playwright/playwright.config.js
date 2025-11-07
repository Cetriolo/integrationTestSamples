// tests/api.spec.js/api.spec.js.config.js
import { defineConfig } from '@api.spec.js/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { outputFolder: 'api.spec.js-report' }],
    ['json', { outputFile: 'test-results.json' }],
    ['list'],
  ],

  use: {
    baseURL: process.env.API_URL || 'http://localhost:8080',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  timeout: 30000,
  expect: {
    timeout: 5000,
  },

  projects: [
    {
      name: 'api-tests',
      testMatch: '**/*.spec.js',
    },
  ],
});