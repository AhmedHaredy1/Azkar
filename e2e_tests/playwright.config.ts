import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 180_000,
  retries: 0,
  reporter: [['html', { outputFolder: 'playwright-report', open: 'never' }], ['list']],
  use: {
    baseURL: 'http://localhost:8888',
    screenshot: 'on',
    trace: 'off',
    video: 'off',
    // Use full Chromium (not headless-shell) to get WebGL support for Flutter CanvasKit
    channel: undefined,
    launchOptions: {
      executablePath: undefined, // use installed chromium, not headless-shell
      args: [
        '--enable-webgl',
        '--enable-accelerated-2d-canvas',
        '--use-gl=swiftshader',       // Software WebGL - works in headless
        '--disable-gpu-sandbox',
        '--disable-software-rasterizer',
        '--ignore-gpu-blocklist',
        '--enable-gpu-rasterization',
        '--no-sandbox',
        '--disable-setuid-sandbox',
      ],
      headless: true,
    },
  },
  projects: [
    {
      name: 'chromium-webgl',
      use: {
        ...devices['Desktop Chrome'],
        // Override to use the full Chromium browser (has WebGL via SwiftShader)
        browserName: 'chromium',
      },
    },
  ],
});
