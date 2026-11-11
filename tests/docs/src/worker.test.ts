import { describe, expect, it, vi } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

import worker, { namesADirectory } from "@/worker/index";

// What reaches the Worker is a request no file matched: under
// `html_handling: "none"` a directory's address (`/`) is one of them. It is
// served as that directory's index.html; anything else is missing.
function assets() {
  return {
    fetch: vi.fn(async (req: Request) => new Response(`asset ${new URL(req.url).pathname}`, { status: 200 })),
  };
}

describe("namesADirectory", () => {
  it("is true for an address ending in a slash", () => {
    for (const p of ["/", "/sb-manager/", "/a/b/"]) expect(namesADirectory(p)).toBe(true);
  });

  it("is false for anything else", () => {
    for (const p of ["/iframe", "/missing.js", "/no/such/page", "/index.html"]) expect(namesADirectory(p)).toBe(false);
  });
});

describe("the Worker", () => {
  it("serves / as the manager's index.html, keeping the query Storybook keeps its page in", async () => {
    const ASSETS = assets();
    const res = await worker.fetch(new Request("https://site.example/?path=/docs/button--docs"), { ASSETS });
    expect(ASSETS.fetch).toHaveBeenCalledOnce();
    const asked = new URL(ASSETS.fetch.mock.calls[0]![0].url);
    expect(asked.pathname).toBe("/index.html");
    expect(asked.search).toBe("?path=/docs/button--docs");
    expect(await res.text()).toBe("asset /index.html");
  });

  it("answers anything else with a plain 404, without asking the assets", async () => {
    for (const p of ["/missing.js", "/iframe", "/no/such/page", "/assets/missing.png"]) {
      const ASSETS = assets();
      const res = await worker.fetch(new Request(`https://site.example${p}`), { ASSETS });
      expect(res.status).toBe(404);
      expect(res.headers.get("content-type")).toBe("text/plain; charset=utf-8");
      expect(ASSETS.fetch).not.toHaveBeenCalled();
    }
  });

  it("keeps the request's method and headers when it asks the assets", async () => {
    const ASSETS = assets();
    await worker.fetch(new Request("https://site.example/", { method: "HEAD", headers: { accept: "text/html" } }), { ASSETS });
    const asked = ASSETS.fetch.mock.calls[0]![0];
    expect(asked.method).toBe("HEAD");
    expect(asked.headers.get("accept")).toBe("text/html");
  });
});

describe("its assets config (apps/docs/wrangler.jsonc)", () => {
  const wrangler = fs.readFileSync(
    path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../apps/docs/wrangler.jsonc"),
    "utf8",
  );

  it("serves the Storybook build behind the Worker", () => {
    expect(wrangler).toContain('"main": "./worker/index.ts"');
    expect(wrangler).toContain('"directory": "./storybook-static"');
    expect(wrangler).toContain('"binding": "ASSETS"');
  });

  it("serves every file at its own address, iframe.html included", () => {
    expect(wrangler).toContain('"html_handling": "none"');
    expect(wrangler).not.toContain("not_found_handling");
  });
});
