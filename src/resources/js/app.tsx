import "../css/app.css";
import "./bootstrap";

import { createInertiaApp, type ResolvedComponent } from "@inertiajs/react";
import { resolvePageComponent } from "laravel-vite-plugin/inertia-helpers";
import { createRoot } from "react-dom/client";

const appName = import.meta.env.VITE_APP_NAME || "Laravel";

createInertiaApp({
    title: (title) => `${title} - ${appName}`,
    // Inertia 3 の resolve は Promise<Component> を要求する（Promise<Module> は不可）ため、
    // resolvePageComponent が返す module から default を取り出して渡す。
    resolve: (name) =>
        resolvePageComponent<{ default: ResolvedComponent }>(
            `./Pages/${name}.tsx`,
            import.meta.glob<{ default: ResolvedComponent }>("./Pages/**/*.tsx"),
        ).then((module) => module.default),
    setup({ el, App, props }) {
        const root = createRoot(el);

        root.render(<App {...props} />);
    },
    progress: {
        color: "#4B5563",
    },
});
