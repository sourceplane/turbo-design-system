# turbo-design-system — implementation status

| Milestone | State | Landed |
|---|---|---|
| DE0 — the spec | ✅ | the repository's first commit and DE-1 |
| DE1 — the design system on Workers | ✅ | DE-2 |
| DE2 — a baseline | ✅ | DE-3, tagged `baseline-v1` |

## Departures from the upstream template

Everything not listed here is the template as it is in vercel/turborepo at
`c30ba0a` (`examples/design-system`).

| # | What | Why |
|---|---|---|
| 1 | `apps/docs/.storybook/site.ts` holds the design system's name (`SITE_NAME = "Design System"`, the example's name), and a new `.storybook/manager.ts` sets Storybook's theme with `brandTitle: SITE_NAME`, its light or dark base from `prefers-color-scheme` | One rename seam; the template names itself nowhere on the page (risk DE-G) |
| 2 | `packageManager` `pnpm@10.12.1` (upstream `pnpm@12.18.0`), `engines.node` `>=22` and `engines.pnpm` `>=10` (upstream node `>=26.13.0`); `pnpm-workspace.yaml` adds `tests/*` and `tooling/*` and lists `onlyBuiltDependencies: [esbuild, workerd]` for pnpm 12's `allowBuilds: { esbuild: true }`; the lockfile is upstream's resolution, installed by pnpm 10 | The composition's pnpm and the runners' Node (risks DE-C, DE-D) |
| 3 | The root `package.json` is named for the repository (upstream `design-system`) and adds `test`; `turbo.json` adds a `test` task (`dependsOn: ["^build"]`) | The workspace's test contract; the repository's own name |
| 4 | `.github/workflows/release.yml` (Changesets version PRs and npm publishing on push to `main`) is dropped; `.changeset/` and the `changeset`, `version-packages` and `release` scripts are kept | `ci.yml` is the only push-to-main workflow (risk DE-F) |
| 5 | `apps/docs` gains `worker/index.ts` and `wrangler.jsonc` (the Worker `<repo>-docs`, `main: ./worker/index.ts`, the `ASSETS` binding over `storybook-static`, `html_handling: "none"`), `component.yaml`, a `preview` script (`wrangler dev`) and `wrangler` 4.157.0; its `tsconfig.json` also checks `worker` | The composition deploys a Worker with its assets; every file at its own address |
| 6 | `packages/eslint-config/library.js` ignores `**/.wrangler/**` beside the builds | wrangler dev's local state is not source |
| 7 | Tests: `tests/docs` (Vitest 5, jsdom, `@testing-library/react`, portable stories) — the Button, the stories, the name seam and theme, the Worker and its config, the built Storybook and library, the licence and Changesets | The template ships none |
| 8 | A `LICENSE.md` (MIT, "Copyright (c) 2026 Vercel, Inc", vercel/turborepo's root `LICENSE`) beside `apps/docs`, `packages/ui`, `packages/eslint-config` and `packages/typescript-config` | The template's licence travels with its packages; `@acme/ui` publishes it with `dist` |
| 9 | `storybook-static/`, the template's `.gitignore` entries and the kit's are one `.gitignore`; `storybook-static` and `packages/ui/dist` are ignored by the blueprint and the leak gate | What a build generates is a build's, not the design system's |
| 10 | The template's README is replaced by `apps/docs/README.md` (the Storybook) and the repository's README; its "create-turbo" instructions map to `orun new` | The repository's own documentation |
| 11 | eslint-plugin-storybook's `@typescript-eslint/utils` peer resolves to the workspace's TypeScript 7.0.2 (pnpm 12 had auto-installed 6.0.3): pnpm reports an unmet peer at install | pnpm 10's peer resolution; the plugin's rules need no type information and lint passes (risk DE-D) |
