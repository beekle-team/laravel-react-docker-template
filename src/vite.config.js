import { wayfinder } from "@laravel/vite-plugin-wayfinder";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import laravel from "laravel-vite-plugin";
import { defineConfig } from "vite";
import { reactCompilerConfig } from "./react-compiler.config.js";

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
        tailwindcss(),
        wayfinder({
            formVariants: true,
        }),
    ],
});
