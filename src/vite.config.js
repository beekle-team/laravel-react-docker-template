import { wayfinder } from "@laravel/vite-plugin-wayfinder";
import react from "@vitejs/plugin-react";
import laravel from "laravel-vite-plugin";
import { defineConfig } from "vite";

// React 18 では compiler runtime が react 本体に同梱されないため、
// react-compiler-runtime の polyfill を使う target を明示する。
const reactCompilerConfig = {
    target: "18",
};

export default defineConfig({
    server: {
        host: "0.0.0.0",
        hmr: {
            host: "localhost",
        },
    },
    plugins: [
        laravel({
            input: "resources/js/app.tsx",
            refresh: true,
        }),
        react({
            babel: {
                plugins: [["babel-plugin-react-compiler", reactCompilerConfig]],
            },
        }),
        wayfinder({
            formVariants: true,
        }),
    ],
});
