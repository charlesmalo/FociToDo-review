import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './journeys',
  workers: 1,
  fullyParallel: false,
  reporter: [['list']],
  use: {
    baseURL: process.env.BASE_URL ?? 'http://web:8080',
    locale: 'en-US',
    timezoneId: 'UTC',
    viewport: { width: 1100, height: 760 },
  },
});
