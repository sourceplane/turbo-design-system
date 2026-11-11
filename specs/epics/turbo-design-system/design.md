# turbo-design-system — design

## The template

Vercel's Design System with Turborepo example (`examples/design-system` in
[vercel/turborepo](https://github.com/vercel/turborepo)) is a pnpm and
Turborepo monorepo:

- `packages/ui` — `@acme/ui`, a publishable React component library with one
  component, `Button` (a `<button type="button">` that passes every other
  attribute through). tsup builds `src/button.tsx` to ES module and CommonJS
  (`dist/button.mjs`, `dist/button.js`), React kept external, then
  `tsc --emitDeclarationOnly` writes `dist/button.d.ts`; `package.json`
  exports `./button` with all three and publishes `dist` only, React a peer.
- `apps/docs` — Storybook 10 with the React Vite framework and the links and
  docs addons, its one story `stories/button.stories.tsx` (the Button, with
  autodocs, its `type` as a radio control, its clicks spied on by `fn()`,
  one story shown as "Button" with an inline style). It imports the
  library's BUILT exports, so turbo builds the library first. Its build is
  `storybook build --docs`: docs mode, the sidebar showing the docs page.
- `packages/eslint-config` and `packages/typescript-config` — ESLint 10 flat
  configs that parse TypeScript with Babel (no typescript-eslint), leaving
  names and unused code to TypeScript 7's `noUnusedLocals` and friends; the
  TypeScript base, library and app configs.
- Changesets, and `.github/workflows/release.yml`, which on every push to
  `main` opens a version PR or publishes `@acme/ui` to npm with `NPM_TOKEN`.

It ships no tests. It asks for pnpm 12.18.0 and Node 26.13.0 or newer.
Vercel builds it with `turbo run build` and serves the static Storybook.

## The template as it is

The research for this row read the example's previous version (Storybook
8.2, React 18, pnpm 8.15.6). On 2026-11-10 upstream rewrote it
(`c30ba0a`): Storybook 10.6.6, React 19.3.1, Vite 8.3.6, TypeScript 7.0.2,
tsup 9.0.0, ESLint 10.14, turbo 2.11.10. This port takes the current
template. Every package it installs accepts Node 22.12 or newer (Storybook
`^20.19 || >=22.12`, Vite `^20.19 || ^22.13 || >=24`, tsup
`^22.18 || ^24.11 || >=26`, ESLint `^20.19 || ^22.13 || >=24`), and the
runners give Node 22.23, so the versions stay and only the floors move:
`engines.node` `>=22`, pnpm 10.12.1 (the composition's). pnpm 10 installs
upstream's pnpm-12 lockfile once its first YAML document (pnpm's own
`packageManagerDependencies`) is dropped, keeping every resolution
(risk DE-D).

## How it maps to Cloudflare

| Vercel | Here | Why |
|---|---|---|
| The static Storybook on Vercel's CDN | `storybook-static` as Workers Static Assets, uploaded with `<repo>-docs-<env>` | Storybook is static; the assets are the Storybook |
| — | One Worker, `apps/docs/worker/index.ts` | The `cloudflare-workers-assets-turbo` composition deploys a Worker with its assets; it answers what the assets leave |
| Each file at its own address | `html_handling: "none"` | The manager frames `iframe.html?id=…`; the default `auto-trailing-slash` would answer it with a 307 to `/iframe` on every preview load |
| `/` is `index.html` | The Worker serves a directory's `index.html` from the assets | Under `"none"` nothing else maps `/` to a file |
| The release workflow | Dropped; Changesets kept for publishing by hand | `ci.yml` is the one workflow on `main`; publishing a library to npm is the owner's decision, with the owner's scope and token |
| No tests | `tests/docs` (Vitest, jsdom) | The component's and the stories' behaviour is what a change must keep |

## Every file at its own address

Storybook keeps every page in the query string: the manager at
`/?path=/docs/button--docs`, the preview it frames at
`/iframe.html?id=button--docs&viewMode=docs`. No page has a path of its own,
so there is no single-page fallback to give and no 404 page to serve. What
matters is that every file answers where Storybook asks for it. With the
assets' default HTML handling, `/iframe.html` is redirected to `/iframe` and
`/index.html` to `/` — the preview still loads, a redirect later. With
`"none"` the assets serve each file at exactly its path, and a request that
matches no file reaches the Worker: a directory's address (`/`, the only one
Storybook uses) is served as its `index.html`, keeping the query, and
anything else is a plain-text 404. `namesADirectory` is the one rule, tested
in `tests/docs/src/worker.test.ts` and read over HTTP by the e2e tier (no
redirect anywhere, a 404 for `/iframe`, `/no/such/page`, `/missing.js`).

## The name seam

The template has no name of its own on the page: the sidebar shows
Storybook's logo, the tab "<story> ⋅ Storybook". The seam is
`apps/docs/.storybook/site.ts` (`SITE_NAME = "Design System"`, the example's
name in its `meta.json`), read by a new `.storybook/manager.ts` that sets
Storybook's theme with `brandTitle: SITE_NAME` — the sidebar shows the
design system's name in place of the logo. The theme's base is light or
dark from `prefers-color-scheme`, which is what Storybook picks with no theme
set, so the template's look is kept (risk DE-G). The name is compiled into
the manager's bundle, where the e2e tier and the tests read it.

## The tests

The template has none. `tests/docs` adds, with Vitest 5:

- the Button from its BUILT export (`@acme/ui/button`), in jsdom: children,
  the default `type`, attributes passed through, clicks, `displayName`;
- the template's stories as Storybook runs them (portable stories,
  `composeStories`): the meta's component, tags and argTypes, the story's
  name, its rendered style, the `fn()` spy, new args re-rendering;
- the name seam and the theme that reads it; the Storybook's config;
- the Worker's rule and `wrangler.jsonc`;
- the built Storybook (`index.json`'s docs page and story from the built
  library, every bundle loaded by relative address, the name in the
  manager's bundle) and the built library (ESM, CJS and types, React a
  peer);
- the licence beside every package of the template, and Changesets kept with
  no workflow publishing.

The package depends on `docs` and `@acme/ui`, so turbo's `test`
(`dependsOn: ["^build"]`) builds both first.

## The repository

The template's tree as it is (`apps/docs`, `packages/ui`,
`packages/eslint-config`, `packages/typescript-config`, `.changeset`), as
turborepo-monorepo kept its template's; vite-react-boilerplate's machinery
around it: the Worker in front of a static Vite build, `tests/docs` in place
of `tests/web`, the wrangler renderer, `ci.yml` byte for byte
vite-react-boilerplate's (turso-starter's but for one comment). The
template's own ESLint and TypeScript packages replace the kit's
`tooling/eslint` and `tooling/tsconfig`: one ESLint (10) and one TypeScript
(7) in the workspace. The component is named `docs`, after the template's
app, in domain `app`; its Worker is `<repo>-docs-<env>`. The rename engine is
vite-react-boilerplate's; the slug is spelled by no module of the
framework's or the template's (`@acme`, `@repo`), so nothing is masked.

## The alternative rejected

**An assets-only deploy, no Worker.** A Worker-less Static Assets deploy with
the default HTML handling would serve the Storybook, at the cost of the
redirect on every preview load. The composition deploys a Worker with its
assets in any case, and one rule in it lets every file answer at its own
address.
