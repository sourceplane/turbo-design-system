import { describe, expect, it } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

// The library as it is published: tsup's ES module and CommonJS builds and
// TypeScript's declarations, behind an explicit export per component.
const ui = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../packages/ui");
const pkg = JSON.parse(fs.readFileSync(path.join(ui, "package.json"), "utf8"));

describe("@acme/ui (packages/ui)", () => {
  it("exports the button's ESM, CJS and types from dist", () => {
    expect(pkg.exports["./button"]).toEqual({
      types: "./dist/button.d.ts",
      import: "./dist/button.mjs",
      require: "./dist/button.js",
    });
    for (const file of Object.values(pkg.exports["./button"]) as string[]) {
      expect(fs.existsSync(path.join(ui, file)), file).toBe(true);
    }
  });

  it("builds with tsup, then writes declarations with tsc", () => {
    expect(pkg.scripts.build).toBe("tsup && tsc --emitDeclarationOnly");
    const tsup = fs.readFileSync(path.join(ui, "tsup.config.ts"), "utf8");
    expect(tsup).toContain('entry: ["src/button.tsx"]');
    expect(tsup).toContain('format: ["cjs", "esm"]');
    expect(tsup).toContain('external: ["react", "react/jsx-runtime"]');
  });

  it("leaves React to the consumer", () => {
    expect(Object.keys(pkg.peerDependencies)).toEqual(["react"]);
    expect(pkg.dependencies ?? {}).toEqual({});
    const esm = fs.readFileSync(path.join(ui, "dist/button.mjs"), "utf8");
    expect(esm).toMatch(/from ["']react\/jsx-runtime["']/);
  });

  it("works from CommonJS too", () => {
    const require = createRequire(path.join(ui, "package.json"));
    const cjs = require("./dist/button.js");
    expect(typeof cjs.Button).toBe("function");
    expect(cjs.Button.displayName).toBe("Button");
  });

  it("publishes dist alone, publicly, under the MIT licence", () => {
    expect(pkg.files).toEqual(["dist"]);
    expect(pkg.publishConfig).toEqual({ access: "public" });
    expect(pkg.license).toBe("MIT");
    expect(fs.readFileSync(path.join(ui, "LICENSE.md"), "utf8")).toContain("Copyright (c) 2026 Vercel, Inc");
  });
});
