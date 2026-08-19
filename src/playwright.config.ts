import { defineConfig, devices } from "playwright/test";

const defaultBaseURL = "http://localhost:8080";
const baseURL = process.env.PLAYWRIGHT_BASE_URL ?? defaultBaseURL;

// 既定の baseURL のときだけ開発サーバを起動する。docker compose や別環境を
// 指す場合は PLAYWRIGHT_BASE_URL を渡して、その環境をそのまま使う。
const webServer = process.env.PLAYWRIGHT_BASE_URL
    ? undefined
    : {
          command: `php artisan serve --host=127.0.0.1 --port=${new URL(defaultBaseURL).port}`,
          url: defaultBaseURL,
          reuseExistingServer: !process.env.CI,
          timeout: 60_000,
      };

export default defineConfig({
    testDir: "./playwright",
    fullyParallel: true,
    retries: process.env.CI ? 2 : 0,
    workers: process.env.CI ? 1 : undefined,
    // CI では annotation 用の github reporter に加えて、失敗時に artifact として
    // 持ち出せる HTML レポートも出力する。
    reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : "list",
    webServer,
    use: {
        baseURL,
        trace: "on-first-retry",
        screenshot: "only-on-failure",
        video: "retain-on-failure",
    },
    projects: [
        {
            name: "chromium",
            use: { ...devices["Desktop Chrome"] },
        },
        {
            name: "firefox",
            use: { ...devices["Desktop Firefox"] },
        },
        {
            name: "webkit",
            use: { ...devices["Desktop Safari"] },
        },
    ],
});
