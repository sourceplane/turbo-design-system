# turbo-design-system

Vercel's [Design System with Turborepo](https://github.com/vercel/turborepo/tree/main/examples/design-system)
template — a React component library, `@acme/ui`, built with tsup and
TypeScript, documented by Storybook in docs mode, with the shared ESLint and
TypeScript configurations and Changesets for versioning — on the template's
Storybook 10, React 19, Vite 8 and TypeScript 7, with its Storybook running
on **Cloudflare Workers + Static Assets**, deployed by
[Orun](https://github.com/sourceplane/orun) to stage and prod on every merge.
Packaging it as an Orun baseline is the next milestone (DE2).

Storybook builds fully static: turbo builds the library first (tsup writes
its ES module and CommonJS builds, `tsc --emitDeclarationOnly` its
declarations), then `storybook build --docs` writes the manager, the preview
it frames (`iframe.html`), the stories' index and the hashed bundles to
`storybook-static`. That folder is uploaded as Workers Static Assets with one
small Worker in front, every file served at its own address — `iframe.html`
answers itself, with no redirect — and a missing file a 404. The library, its
story and the shared configs do not change; the design system's name moves
into one module, which the Storybook's theme shows as its title, and the
template, which ships no tests, gains Vitest suites of the component and its
stories as they behave. See
[`specs/epics/turbo-design-system`](specs/epics/turbo-design-system/README.md)
for the design, the milestones and the as-built status.

## What is here (the monorepo)

| Surface | Where |
|---|---|
| The component library (the template's): the Button, its tsup build and its exports | `packages/ui` |
| The Storybook (the template's): its config, the Button's story | `apps/docs/.storybook/main.ts`, `apps/docs/stories/button.stories.tsx`, `apps/docs/vite.config.ts` |
| The design system's name, which the Storybook's theme shows as its title | `apps/docs/.storybook/site.ts`, `apps/docs/.storybook/manager.ts` |
| The shared ESLint and TypeScript configurations (the template's) | `packages/eslint-config`, `packages/typescript-config` |
| Versioning the library (the template's Changesets, by hand) | `.changeset/` |
| The Worker in front of the assets, its config, deploy contract | `apps/docs/worker/index.ts`, `apps/docs/wrangler.jsonc`, `apps/docs/component.yaml` |
| Tests (new: the template ships none) — the Button, the stories, the name seam, the Worker, the built Storybook and library | `tests/docs` (vitest, jsdom) |

## Getting started

```bash
pnpm install
pnpm check-types      # tsc: the library, the Storybook, the Worker and the tests
pnpm lint             # eslint (the template's flat configs)
pnpm test             # vitest: tests/docs, after building the library and the Storybook
pnpm build            # the library (tsup + tsc) and the Storybook → apps/docs/storybook-static
```

```bash
pnpm dev                        # the library in watch mode and Storybook on http://localhost:6006
pnpm --filter docs preview      # wrangler dev over the built Storybook and its Worker
```

## How it maps to Vercel

| Vercel | Here |
|---|---|
| The static Storybook on Vercel's CDN, from `pnpm build` | Workers Static Assets: `storybook-static` uploaded with the Worker `<repo>-docs-<env>` (`apps/docs/wrangler.jsonc`) |
| The template's build (`turbo run build`: tsup and `tsc` for `@acme/ui`, `storybook build --docs` for the docs) | The same tasks, through turbo, on the template's Storybook 10, React 19, Vite 8 and TypeScript 7 |
| Each file served at its own address (`/iframe.html`) | `html_handling: "none"`, so `/iframe.html` answers itself instead of redirecting to `/iframe`; the Worker serves `/` as `index.html`, and anything else that matches no file is a 404 |
| No tests | `tests/docs`: the Button and the template's story (portable stories) rendered in jsdom by Vitest, the built Storybook's index and bundles, the built library's ESM, CJS and types |
| The release workflow: Changesets on push to `main`, publishing `@acme/ui` to npm with `NPM_TOKEN` | Dropped: `ci.yml` is the one workflow on `main` (Orun's). The Changesets config and the `changeset`, `version-packages` and `release` scripts stay, to version and publish by hand |
| pnpm 12, Node 26 | pnpm 10.12.1 and Node 22, the runners' (every package the template uses accepts Node 22.12 or newer) |
| Deploy on push | Orun deploys `<repo>-docs-{stage,prod}` on merge to `main` (`apps/docs/component.yaml`) |
| "Deploy with Vercel" (clone the template) | `orun new --blueprint repo-blueprint.yaml` — a new repository, branded, deployed |

## CI

| Workflow | What it runs | Ships to a design system |
|---|---|---|
| `ci.yml` | the Orun pipeline, and the only workflow a design system carries: `orun plan --changed`, then one job per lane. A pull request runs the verify lanes (the Storybook built and dry-deployed per environment; the tests' `quick-check` lane installs and checks the package, it does not run them), except the bootstrap's own landings (`orun/BASE-*`), where `plan` alone is the check; a merge deploys stage → prod. It plans nothing while `intent.yaml` names the placeholder workspace `ws_CHANGE_ME`, as this repository does. A manual run (Orunbase's Deploy button, or Run workflow on `main`) plans the environment and components it names under the push-to-main trigger, so they deploy as a merge deploys them | yes |

## Credits

The design system is Vercel's Turborepo example
([vercel/turborepo](https://github.com/vercel/turborepo), `examples/design-system`,
© 2026 Vercel, MIT — `apps/docs/LICENSE.md`, `packages/*/LICENSE.md`), at
vercel/turborepo `c30ba0a`.
