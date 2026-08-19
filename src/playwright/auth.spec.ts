import { expect, test } from "playwright/test";

test.describe("Registration", () => {
    test("新規登録するとメール確認を促される", async ({ page }) => {
        // 実行ごとに一意なアドレスにして、DB の状態に依存しないようにする。
        const email = `e2e-${Date.now()}-${Math.random().toString(36).slice(2, 8)}@example.com`;

        await page.goto("/register");
        await page.getByLabel("Name").fill("E2E User");
        await page.getByLabel("Email").fill(email);
        await page.getByLabel("Password", { exact: true }).fill("password-1234");
        await page.getByLabel("Confirm Password").fill("password-1234");
        await page.getByRole("button", { name: "Register" }).click();

        await expect(page).toHaveURL(/\/verify-email$/);
        await expect(page.getByText(/Thanks for signing up/i)).toBeVisible();
        await expect(page.getByRole("button", { name: "Resend Verification Email" })).toBeVisible();
    });
});

test.describe("Login", () => {
    test("誤った資格情報ではエラーを表示する", async ({ page }) => {
        await page.goto("/login");
        await page.getByLabel("Email").fill("no-such-user@example.com");
        await page.getByLabel("Password", { exact: true }).fill("wrong-password");
        await page.getByRole("button", { name: "Log in" }).click();

        await expect(page.getByText(/do not match our records/i)).toBeVisible();
        await expect(page).toHaveURL(/\/login$/);
    });

    test("未認証では dashboard にアクセスできない", async ({ page }) => {
        await page.goto("/dashboard");

        await expect(page).toHaveURL(/\/login$/);
    });
});
