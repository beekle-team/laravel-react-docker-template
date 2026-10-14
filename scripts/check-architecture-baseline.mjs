import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

// Accept only PHPStan's generated, count-limited baseline format.
export function entries(source) {
    const result = new Map();
    let entry;
    for (const line of source.split(/\r?\n/)) {
        const value = line.trim();
        if (!value || value.startsWith("#") || value === "parameters:" || value === "ignoreErrors:" || value === "ignoreErrors: []") continue;
        if (value === "-") {
            if (entry) add(entry);
            entry = {};
            continue;
        }
        const match = /^(message|identifier|count|path): (.+)$/.exec(value);
        if (!entry || !match || match[1] in entry) throw new Error("Unsupported baseline line: " + value);
        entry[match[1]] = match[2];
    }
    if (entry) add(entry);
    return result;

    function add(row) {
        if (!row.message || !row.path || !row.identifier?.startsWith("architecture.") || !/^[1-9]\d*$/.test(row.count ?? "")) {
            throw new Error("Every baseline entry needs an architecture identifier, message, path and positive count.");
        }
        const key = JSON.stringify([row.identifier, row.path, row.message]);
        if (result.has(key)) throw new Error("Duplicate baseline entry.");
        result.set(key, Number(row.count));
    }
}

export function assertNotIncreased(previous, current) {
    const before = entries(previous);
    for (const [key, count] of entries(current)) {
        if (count > (before.get(key) ?? 0)) {
            throw new Error("Architecture baseline must not grow: " + key);
        }
    }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
    const baseline = "src/phpstan-architecture-baseline.neon";
    const base = process.argv[2] ?? "origin/main";
    const current = readFileSync(baseline, "utf8");
    entries(current);
    // Fail for missing revision; only first adoption may have no baseline file.
    const files = execFileSync("git", ["ls-tree", "--name-only", base, "--", baseline], { encoding: "utf8" });
    if (files.trim()) {
        assertNotIncreased(execFileSync("git", ["show", base + ":" + baseline], { encoding: "utf8" }), current);
        console.log("Architecture baseline has not increased.");
    } else {
        console.log("Initial architecture baseline: review every entry in this PR.");
    }
}
