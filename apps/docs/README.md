# apps/docs — the design system's Storybook

[Storybook](https://storybook.js.org) 10 with the React Vite framework,
documenting the `@acme/ui` library (`packages/ui`) as Vercel's Design System
with Turborepo example (MIT, `LICENSE.md`) ships it — built fully static in
docs mode and served as Cloudflare Workers + Static Assets:

- `.storybook/main.ts`: the stories under `stories/`, the links and docs
  addons, the React Vite framework — the template's
- `stories/button.stories.tsx`: the Button, documented with autodocs, its
  type as a radio control and its clicks spied on — the template's
- `.storybook/site.ts` and `.storybook/manager.ts`: the design system's name,
  which Storybook's theme shows as its title (light or dark, as the system
  prefers)

The stories import the library's BUILT exports (`@acme/ui/button` →
`packages/ui/dist`), so turbo builds the library before Storybook starts or
builds.

`worker/index.ts` sits in front of the static build: the assets answer every
file at its own address (`html_handling: "none"` in `wrangler.jsonc`, so
`iframe.html` is never redirected), and the Worker answers what is left — a
directory's address (`/`) with its `index.html`, and anything else with a
404. Storybook keeps its pages in the query string, so no page is lost.

```bash
pnpm dev        # storybook dev on http://localhost:6006
pnpm build      # storybook build --docs → storybook-static
pnpm preview    # wrangler dev over the built Storybook, behind worker/index.ts
```

How it is deployed — per environment, on merge to `main` — is the
repository's README and `component.yaml` beside this file.
