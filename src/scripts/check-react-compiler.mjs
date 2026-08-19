#!/usr/bin/env node

// React Compiler が最適化をスキップしたコンポーネント / フックを検出する。
// ビルド時のコンパイラはスキップしても警告を出さず成功するため、
// 静的検査としてビルドと同じプラグインを走らせ、スキップを CI で失敗させる。

import { readFileSync, readdirSync } from "node:fs";
import { extname, join, relative } from "node:path";
import { parseAsync, transformAsync, traverse } from "@babel/core";
import { OPT_OUT_DIRECTIVES } from "babel-plugin-react-compiler";
import { reactCompilerCheckConfig } from "../react-compiler.config.js";

const TARGET_DIR = "resources/js";

// Wayfinder 生成物と型定義はコンポーネントを含まないので検査しない。
const IGNORED_DIRS = new Set(["actions", "routes", "wayfinder"]);

const FAILURE_KINDS = new Set([
    "CompileError",
    "CompileSkip",
    "PipelineError",
    "CompileDiagnostic",
]);

function collectSourceFiles(dir) {
    const files = [];

    for (const entry of readdirSync(dir, { withFileTypes: true })) {
        const path = join(dir, entry.name);

        if (entry.isDirectory()) {
            if (!IGNORED_DIRS.has(entry.name)) {
                files.push(...collectSourceFiles(path));
            }
            continue;
        }

        if (entry.name.endsWith(".d.ts")) {
            continue;
        }

        if (extname(entry.name) === ".ts" || extname(entry.name) === ".tsx") {
            files.push(path);
        }
    }

    return files;
}

// コンパイラは opt-out された関数でも検証イベントを出すため、
// 明示的に除外された関数の範囲を集めて報告対象から外す。
async function collectOptedOutRanges(code, parserOpts) {
    const ast = await parseAsync(code, { babelrc: false, configFile: false, parserOpts });
    const ranges = [];

    traverse(ast, {
        Function(path) {
            const directives = path.node.body?.directives ?? [];

            if (directives.some((directive) => OPT_OUT_DIRECTIVES.has(directive.value.value))) {
                ranges.push([path.node.start, path.node.end]);
            }
        },
    });

    return ranges;
}

function isOptedOut(event, ranges) {
    const start = event.fnLoc?.start?.index;

    if (start == null) {
        return false;
    }

    return ranges.some(([from, to]) => start >= from && start <= to);
}

function describe(event, code) {
    const detail = event.detail;

    if (typeof detail?.printErrorMessage === "function") {
        return detail.printErrorMessage(code, { eslint: false });
    }

    return event.reason ?? event.data ?? detail?.reason ?? event.kind;
}

async function checkFile(file) {
    const code = readFileSync(file, "utf8");
    const failures = [];
    let compiled = 0;

    // .ts での型引数と JSX の構文衝突を避けるため、jsx は .tsx にだけ有効化する。
    const parserOpts = {
        plugins: extname(file) === ".tsx" ? ["jsx", "typescript"] : ["typescript"],
    };
    const optedOutRanges = await collectOptedOutRanges(code, parserOpts);

    await transformAsync(code, {
        filename: file,
        babelrc: false,
        configFile: false,
        parserOpts,
        plugins: [
            [
                "babel-plugin-react-compiler",
                {
                    ...reactCompilerCheckConfig,
                    logger: {
                        logEvent(_filename, event) {
                            if (event.kind === "CompileSuccess") {
                                compiled += 1;
                                return;
                            }

                            if (
                                FAILURE_KINDS.has(event.kind) &&
                                !isOptedOut(event, optedOutRanges)
                            ) {
                                failures.push({ kind: event.kind, message: describe(event, code) });
                            }
                        },
                    },
                },
            ],
        ],
    });

    return { compiled, failures, optedOut: optedOutRanges.length };
}

const files = collectSourceFiles(TARGET_DIR);
let compiledTotal = 0;
let optedOutTotal = 0;
let failureTotal = 0;

for (const file of files) {
    let result;

    try {
        result = await checkFile(file);
    } catch (error) {
        failureTotal += 1;
        console.error(`\n${relative(process.cwd(), file)} [ParseError]`);
        console.error(error.message);
        continue;
    }

    const { compiled, failures, optedOut } = result;
    compiledTotal += compiled;
    optedOutTotal += optedOut;

    for (const failure of failures) {
        failureTotal += 1;
        console.error(`\n${relative(process.cwd(), file)} [${failure.kind}]`);
        console.error(failure.message);
    }
}

if (failureTotal > 0) {
    console.error(
        `\nReact Compiler が最適化できないコードが ${failureTotal} 件あります` +
            `（最適化できたコンポーネント / フック: ${compiledTotal} 件）。`,
    );
    console.error(
        "Rules of React 違反を修正してください。回避する場合は該当箇所に " +
            '"use no memo" を付け、理由をコメントで残してください。',
    );
    process.exit(1);
}

console.log(
    `React Compiler: ${files.length} ファイル中 ${compiledTotal} 件のコンポーネント / フックを最適化` +
        `（opt-out ${optedOutTotal} 件）。`,
);
