import { fileURLToPath } from "node:url";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vitest/config";
import { reactCompilerConfig } from "./react-compiler.config.js";

// laravel-vite-plugin と wayfinder はビルド専用なので読み込まない。
// React Compiler は本番ビルドと同じ変換をテストでも通すために有効化する。
export default defineConfig({
    plugins: [
        react({
            babel: {
                plugins: [["babel-plugin-react-compiler", reactCompilerConfig]],
            },
        }),
    ],
    resolve: {
        alias: {
            "@": fileURLToPath(new URL("./resources/js", import.meta.url)),
        },
    },
    test: {
        environment: "jsdom",
        globals: true,
        setupFiles: ["./resources/js/test/setup.ts"],
        include: ["resources/js/**/*.test.{ts,tsx}"],
        restoreMocks: true,
    },
});
