import { strict as assert } from "node:assert";
import { test } from "node:test";
import { assertNotIncreased, entries } from "./check-architecture-baseline.mjs";

const baseline = (count, path = "app/Example.php") => [
    "parameters:",
    "    ignoreErrors:",
    "        -",
    "            message: '#^example$#'",
    "            identifier: architecture.layerBoundary",
    "            count: " + count,
    "            path: " + path,
    "",
].join("\n");

test("allows unchanged or reduced debt", () => {
    assertNotIncreased(baseline(2), baseline(2));
    assertNotIncreased(baseline(2), baseline(1));
    assertNotIncreased(baseline(2), "parameters:\n    ignoreErrors: []\n");
});

test("rejects increased counts and new files", () => {
    assert.throws(() => assertNotIncreased(baseline(1), baseline(2)));
    assert.throws(() => assertNotIncreased(baseline(1), baseline(1, "app/New.php")));
});

test("rejects broad, malformed or duplicate exceptions", () => {
    assert.throws(() => entries("parameters:\n ignoreErrors:\n - '#anything#'"));
    assert.throws(() => entries(baseline(0)));
    assert.throws(() => entries(baseline(1).replace("architecture.layerBoundary", "method.notFound")));
    assert.throws(() => entries(baseline(1) + baseline(1)));
});
