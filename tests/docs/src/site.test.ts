import { describe, expect, it } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

const appDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../apps/docs");
const read = (rel: string) => fs.readFileSync(path.join(appDir, rel), "utf8");

describe("the design system's name (apps/docs/.storybook/site.ts)", () => {
  it("names the design system", async () => {
    const { SITE_NAME } = await import("@/.storybook/site");
    expect(SITE_NAME.trim()).not.toBe("");
  });

  it("is a literal the rename seam can find", () => {
    expect(read(".storybook/site.ts")).toMatch(/^export const SITE_NAME = "[^"]+";$/m);
  });

  it("is the Storybook theme's brand title, the theme still the system's light or dark", () => {
    const manager = read(".storybook/manager.ts");
    expect(manager).toContain('import { SITE_NAME } from "./site";');
    expect(manager).toContain('import { addons } from "storybook/manager-api";');
    expect(manager).toContain('import { create } from "storybook/theming";');
    expect(manager).toContain('matchMedia?.("(prefers-color-scheme: dark)")');
    expect(manager).toContain('create({ base: dark ? "dark" : "light", brandTitle: SITE_NAME })');
  });

  it("is spelled nowhere else in the app", async () => {
    const { SITE_NAME } = await import("@/.storybook/site");
    for (const file of [".storybook/main.ts", ".storybook/manager.ts", "stories/button.stories.tsx", "vite.config.ts", "worker/index.ts"]) {
      expect(read(file)).not.toContain(`"${SITE_NAME}"`);
    }
  });
});

describe("the Storybook (apps/docs/.storybook/main.ts)", () => {
  it("is the template's: its stories, the links and docs addons, the React Vite framework", () => {
    const main = read(".storybook/main.ts");
    expect(main).toContain('stories: ["../stories/**/*.stories.@(ts|tsx)"]');
    expect(main).toContain('addons: ["@storybook/addon-links", "@storybook/addon-docs"]');
    expect(main).toContain('framework: "@storybook/react-vite"');
  });

  it("builds in docs mode into storybook-static, which wrangler.jsonc serves", () => {
    const pkg = JSON.parse(read("package.json"));
    expect(pkg.scripts.build).toBe("storybook build --docs");
    expect(pkg.scripts.dev).toBe("storybook dev -p 6006");
    expect(read("wrangler.jsonc")).toContain('"directory": "./storybook-static"');
  });

  it("consumes the library from the workspace, as a consumer would", () => {
    const pkg = JSON.parse(read("package.json"));
    expect(pkg.dependencies["@acme/ui"]).toBe("workspace:*");
    expect(read("stories/button.stories.tsx")).toContain('import { Button } from "@acme/ui/button";');
  });
});
