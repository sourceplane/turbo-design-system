// The site's Worker. `storybook build --docs` writes the design system's
// Storybook as static files in storybook-static — index.html (the manager),
// iframe.html (the preview every story and docs page renders in), index.json,
// the manager's and the addons' bundles, the hashed assets and the fonts —
// uploaded as Workers Static Assets with `html_handling: "none"` in
// wrangler.jsonc, so a file is served at its own address: `/iframe.html`
// answers itself, as it does on Vercel, instead of a redirect to `/iframe`.
//
//   - a request that matches a file is served from the assets, and never
//     reaches this Worker;
//   - a directory's address (`/`) matches no file under `"none"`: it reaches
//     this Worker, which serves the directory's index.html from the assets;
//   - anything else matched no file, so it is missing: a 404. Storybook keeps
//     every page in the query string (`/?path=/docs/button--docs`), so a
//     missing path is never one of its pages.
//
// It exists because a Workers + Static Assets deploy has a Worker in front of
// the assets — the place a redirect, a header or an API route goes when the
// site needs one.
interface Env {
  ASSETS: { fetch(request: Request): Promise<Response> };
}

/** The address of a directory: the path ends with a slash. */
export function namesADirectory(pathname: string): boolean {
  return pathname.endsWith("/");
}

export default {
  fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (namesADirectory(url.pathname)) {
      url.pathname += "index.html";
      return env.ASSETS.fetch(new Request(url, request));
    }
    return Promise.resolve(
      new Response("Not Found\n", { status: 404, headers: { "content-type": "text/plain; charset=utf-8" } }),
    );
  },
};
