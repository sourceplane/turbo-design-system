import { describe, expect, it } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

// The BUILT Storybook, as wrangler.jsonc uploads it. This package depends on
// `docs`, so turbo's `test` (dependsOn ^build) runs `storybook build --docs`
// first; a missing file here is a build that failed to write it.
const out = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../apps/docs/storybook-static");
const read = (rel: string) => fs.readFileSync(path.join(out, rel), "utf8");

describe("the built Storybook (apps/docs/storybook-static)", () => {
  it("has the manager, the preview and the index", () => {
    for (const file of ["index.html", "iframe.html", "index.json", "project.json", "favicon.svg"]) {
      expect(fs.existsSync(path.join(out, file)), file).toBe(true);
    }
  });

  it("indexes the button's docs page and its story, from the built library", () => {
    const index = JSON.parse(read("index.json"));
    expect(index.entries["button--docs"]).toMatchObject({ type: "docs", title: "button", name: "Docs" });
    expect(index.entries["button--primary"]).toMatchObject({
      type: "story",
      title: "button",
      name: "Button",
      importPath: "./stories/button.stories.tsx",
      componentPath: "../../packages/ui/dist/button.mjs",
    });
    expect(index.entries["button--primary"].tags).toContain("autodocs");
  });

  it("loads every bundle from its own origin, by relative address", () => {
    for (const shell of ["index.html", "iframe.html"]) {
      const html = read(shell);
      const loads = [...html.matchAll(/<(?:script|link)[^>]+(?:src|href)="([^"]+)"/g)].map((m) => m[1]!);
      expect(loads.length, shell).toBeGreaterThan(0);
      for (const url of loads) {
        expect(url, `${shell} loads ${url}`).toMatch(/^\.\//);
        expect(fs.existsSync(path.join(out, url)), `${shell} loads ${url}, which the build did not write`).toBe(true);
      }
    }
  });

  it("carries the design system's name in the manager's bundle", async () => {
    const { SITE_NAME } = await import("@/.storybook/site");
    const bundles = [...read("index.html").matchAll(/import '\.\/(sb-addons\/[^']+\/manager-bundle\.js)'/g)].map((m) => m[1]!);
    expect(bundles.length).toBeGreaterThanOrEqual(3);
    expect(bundles.some((b) => read(b).includes(JSON.stringify(SITE_NAME)))).toBe(true);
  });
});
