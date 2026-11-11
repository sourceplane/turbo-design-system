import { describe, expect, it } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
const read = (rel: string) => fs.readFileSync(path.join(repo, rel), "utf8");

describe("the template's licence and credit", () => {
  it("ships the MIT licence with Vercel's copyright beside every package of the template", () => {
    for (const dir of ["apps/docs", "packages/ui", "packages/eslint-config", "packages/typescript-config"]) {
      const licence = read(`${dir}/LICENSE.md`);
      expect(licence, dir).toContain("Copyright (c) 2026 Vercel, Inc");
      expect(licence, dir).toContain("Permission is hereby granted, free of charge");
    }
  });
});

describe("the template's versioning (.changeset)", () => {
  it("keeps Changesets for the library, by hand: no workflow publishes to npm", () => {
    const config = JSON.parse(read(".changeset/config.json"));
    expect(config.access).toBe("public");
    expect(config.ignore).toEqual(["docs"]);
    const root = JSON.parse(read("package.json"));
    expect(root.scripts.changeset).toBe("changeset");
    expect(root.scripts.release).toBe("turbo run build --filter=docs^... && changeset publish");
    const workflows = fs.readdirSync(path.join(repo, ".github/workflows"));
    for (const wf of workflows) {
      expect(read(`.github/workflows/${wf}`), wf).not.toContain("changeset publish");
      expect(read(`.github/workflows/${wf}`), wf).not.toContain("NPM_TOKEN");
    }
  });
});

describe("the shared configs (packages/eslint-config, packages/typescript-config)", () => {
  it("lint TypeScript with Babel, leaving names and unused code to TypeScript 7", () => {
    const library = read("packages/eslint-config/library.js");
    expect(library).toContain('import babelParser from "@babel/eslint-parser";');
    expect(library).toContain('"no-undef": "off"');
    const base = JSON.parse(read("packages/typescript-config/base.json"));
    expect(base.compilerOptions.noUnusedLocals).toBe(true);
    expect(base.compilerOptions.strict).toBe(true);
  });

  it("ignore wrangler's local output alongside the builds", () => {
    expect(read("packages/eslint-config/library.js")).toContain('"**/.wrangler/**"');
  });
});
