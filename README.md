# turbo-design-system

Vercel's [Design System with Turborepo](https://github.com/vercel/turborepo/tree/main/examples/design-system)
template — a React component library, `@acme/ui`, built with tsup and
TypeScript, documented by Storybook in docs mode, with the shared ESLint and
TypeScript configurations and Changesets for versioning — on the template's
Storybook 10, React 19, Vite 8 and TypeScript 7, with its Storybook running
on **Cloudflare Workers + Static Assets**, and packaged as an **Orun
baseline**: one command takes a new design system from nothing to live on
stage and prod, in its own repository, under its own name.

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
stories as they behave. What the baseline adds is everything needed to make a
copy of it somebody else's — built the way
[cirrus-baseline](https://github.com/sourceplane/cirrus-baseline) is. See
[`specs/epics/turbo-design-system`](specs/epics/turbo-design-system/README.md)
for the design, the milestones and the as-built status.

## Instantiating a monorepo

```bash
git clone --depth 1 --branch <baseline-tag> https://github.com/sourceplane/turbo-design-system
cd turbo-design-system
orun new --blueprint repo-blueprint.yaml --out ~/sites/acme-ui --run-hooks --resume \
  --set reponame=acme-ui --set productname="Acme UI" \
  --set githuborg=acme-inc --set subdomain=<workers-dev-subdomain>
```

Or, once the platform's registry lists it, from the Orun console (Baselines →
`turbo-design-system` → Build). Two phases — `01-product` (the repository
created, then the whole design system in one pull request, the Storybook
deployed to stage and prod and smoke-tested) and `03-docs` (the live
deployment recorded) — each landing one pull request in the new repository.
**[BOOTSTRAP.md](BOOTSTRAP.md)** is the operator guide;
[docs/phases/](docs/phases/README.md) has a page per phase.

The new repository receives the **design system only** — the library, its
Storybook and their tests, the shared configs, its CI, its tooling, a README
of its own and its operating contract — renamed throughout to the design
system's name, repository and Cloudflare Worker. None of this repository's
machinery ships.

| What makes it a baseline | Where |
|---|---|
| The console card (inputs, secrets, programme) | `blueprint.yaml` |
| The build document (modules, phases, hooks) | `repo-blueprint.yaml` |
| This tree's identity, and the bootstrap's task contracts | `.baseline/` |
| The rename engine | `tooling/rebrand/rebrand.mjs` |
| The bootstrap's helpers (deferrals, redeploy marker, work-tree strip) | `tooling/bootstrap/` |
| The deployment-record renderer | `hooks/render-deployment-docs.sh` |
| The design system's README and context pack | `.baseline/product/README.md`, `ai/context/` |
| The baseline's tests: contract, leak, offline bootstrap, end to end | `testing/`, `.github/workflows/baseline.yml` |
| Cutting a `baseline-vN` tag | `.github/workflows/tag.yml` |

The framework's name is not the design system's: Storybook's, React's and
Vite's packages, and the template's own `@acme/ui`, `@repo/eslint-config` and
`@repo/typescript-config`, never spell this repository's slug, so the rename
engine has nothing of the framework's to mask. The display name is one
literal, `SITE_NAME` in `apps/docs/.storybook/site.ts` (`Design System`, the
template's own name); the placement tier fails on any placed tree that spells
it anywhere else in the Storybook, or imports a module that is not
Storybook's, React's, Vite's, the library's or the app's own.

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
| `baseline.yml` | the baseline's own tiers: contract tests, the blueprint read by the pinned orun, the leak gate, the offline bootstrap, the Storybook built in a staged job tree, dry-deployed and served | no |
| `tag.yml` | cuts a `baseline-vN` tag (manual) | no |

## Credits

The design system is Vercel's Turborepo example
([vercel/turborepo](https://github.com/vercel/turborepo), `examples/design-system`,
© 2026 Vercel, MIT — `apps/docs/LICENSE.md`, `packages/*/LICENSE.md`), at
vercel/turborepo `c30ba0a`.
