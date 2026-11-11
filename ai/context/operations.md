# turbo-design-system — operating contract (for humans and agents)

This is the standing guide to how this design system is deployed and operated.
Instance facts (live URLs, workspace, the secrets it uses) live in
[deployment.md](deployment.md), rendered from probed reality by the
bootstrap's `03-docs` phase; this file is the contract that stays true
between deployments. It is written to give an agent with repository read
access enough context to reason about and operate the design system
without any other source.

## What this system is

A Turborepo design system on Cloudflare alone, expressed as an Orun
component-native desired-state repo.

- **`packages/ui`** — `@acme/ui`, the React component library: tsup builds
  each component to ES module and CommonJS in `dist`, and
  `tsc --emitDeclarationOnly` writes its declarations; `package.json`
  exports each component. It is a plain workspace package, not a deployed
  component, and no workflow publishes it.
- **`apps/docs`** — the Storybook: Storybook 10 with the React Vite
  framework, documenting the library from its BUILT exports.
  `storybook build --docs` writes the manager (`index.html`), the preview
  (`iframe.html`), the stories' index (`index.json`) and the hashed bundles
  to `storybook-static`, which deploys as Workers Static Assets behind one
  small Worker (`worker/index.ts`). Every file is served at its own address
  (`html_handling: "none"`): Storybook keeps its pages in the query string,
  so nothing is rewritten or redirected. The Worker answers what the assets
  leave — `/` with `index.html`, anything else with a 404. There is no
  database, no server rendering and no runtime secret.
- **`tests/docs`** — the component, story, name-seam, Worker and built-output
  tests (vitest, jsdom), verified on the `dev` rung.
- **`packages/eslint-config`, `packages/typescript-config`** — the shared
  ESLint and TypeScript configuration.
- **`tooling/wire`** — the deploy-time wrangler renderer for workers that
  take wiring (the Storybook takes none).

Environments: **`stage`** and **`prod`** are deployed; **`dev` is
verify-only by design** — lanes build and test, nothing deploys.

## Identity and tenancy

Every remote operation runs against ONE Orun workspace, declared in
`intent.yaml` under `execution.state.workspace` — committed, enforced, and
what CI uses. Do not remove it; headless credentials depend on it. If it
reads `ws_SET_ME`, the bootstrap had no workspace to write: set the real one
before anything else.

## How deployment works

1. Merge (or push) to `main`.
2. CI (`.github/workflows/ci.yml`) runs `orun plan --changed` — only
   components whose files changed are planned — then runs each planned lane
   with `orun run --remote-state`, authenticated by GitHub OIDC (the
   exchange resolves this repository's linked workspace server-side).
3. `apps/docs` builds once per environment (`turbo run build --filter=docs`:
   the library with tsup and `tsc`, then `storybook build --docs`; nothing
   writes an absolute URL, so the build is the same everywhere), then
   `wrangler deploy` ships `turbo-design-system-docs-<env>` with
   `storybook-static` as its assets, and a smoke test fetches `/` (the
   manager), `iframe.html` (the preview, at its own address), `index.json`
   (the Button's docs page and story) and the Button story's chunk the
   preview loads, and checks that a missing file answers 404.
4. `prod` deploys after `stage` has converged on the same commit
   (`environments.prod.promotion` in intent.yaml).
5. **The convergence run is the deployment.** A green run means every
   planned lane applied. Failed lanes are retried with
   `gh run rerun --failed`, which resumes the same execution.

Caveats that matter:

- A push that touches no component files plans zero lanes — that run is
  green and deployed nothing. Never treat "latest run green" as "site
  converged"; probe the URLs instead.
- A change to `intent.yaml` alone maps to no component and redeploys nothing
  on its own. Land it with a change under `apps/docs`. A change under
  `packages/ui` alone redeploys nothing either: `apps/docs` is the component
  that deploys, so land a library change with a story or a marker change
  under `apps/docs`.
- The build runs with its dependencies inside the job's own tree, as
  `intent.yaml`'s stack-tectonic 0.19.0 pin plans it (its comment says why).
  Do not bump it without building `apps/docs` in a job tree staged the way
  the new composition plans it.
- Every file answers at its own address and `/` is `index.html`; any
  other path is a 404. Storybook's pages live in the query string
  (`/?path=/docs/button--docs`), so none is lost — `namesADirectory` in
  `worker/index.ts` is the rule.

## Secrets model

- **Brokered provider secrets**: `CLOUDFLARE_API_TOKEN` (Workers deploy
  scope) and `CLOUDFLARE_ACCOUNT_ID` — pointers minted per run from the
  workspace's Cloudflare connection. No long-lived values at rest; nothing
  to rotate by hand.
- Inspect by NAME only: `orun secrets list --org <ws> --project` and
  `--env stage|prod`. No tooling in this repository prints a secret value,
  and no document in `ai/context/` may contain one.
- The Storybook needs no runtime secret.

## Verifying the system

```bash
# the Storybook on each environment (also recorded, probed, in deployment.md)
curl -s -o /dev/null -w '%{http_code}\n' https://turbo-design-system-docs-stage.your-workers-subdomain.workers.dev/
curl -s https://turbo-design-system-docs-prod.your-workers-subdomain.workers.dev/index.json | grep -c '"button--primary"'

# workspace readiness (integrations + repository link)
orun integrations list --org <ws> --json && orun cloud check --org <ws>
```

## Common operations

| task | how |
|---|---|
| add a component | a `.tsx` file under `packages/ui/src/`, an entry in `packages/ui/tsup.config.ts`, an export in `packages/ui/package.json`, and its story under `apps/docs/stories/`, merge |
| add a docs page | an `.mdx` file under `apps/docs/stories/` and its pattern in `.storybook/main.ts`'s `stories`, merge |
| rename the design system | edit `apps/docs/.storybook/site.ts` (`SITE_NAME`), merge |
| publish the library | by hand: your own scope in place of `@acme`, then `pnpm changeset`, `pnpm version-packages`, `pnpm release` with an npm token — no workflow publishes |
| deploy a change | merge to `main`; watch the run; failed lanes → `gh run rerun --failed` |
| deploy by hand | Orunbase's Deploy button, or `gh workflow run ci.yml --ref main -f environment=<env> [-f component=<a,b>]` — the named components (blank: every one) run in that environment as a merge runs them; started off `main` it is refused |
| redeploy without a change | edit the last line of `apps/docs/component.yaml` (`# orun: redeploy <reason> <stamp>`) and merge — it is a deploy trigger, nothing reads it |
| serve a custom domain | attach it to the Worker in Cloudflare and set `SITE_URL` for the environment in `intent.yaml` — the deployment record probes it (README, "Custom domain") — then replace the placeholder `turbo-design-system.example.com` in `intent.yaml`'s `BASE_DOMAIN` (dev, stage and prod) with it |
| add a runtime secret | `orun secrets set <KEY> --org <ws> --env <env>` |
| headless credentials | `ORUN_TOKEN` (workspace-scoped) + `GITHUB_TOKEN` |

The deployment record is the bootstrap's `03-docs` phase. Re-running it (the
Orun console's Retry on that phase, or `orun new … --phase 03-docs`)
re-probes the URLs and re-renders [deployment.md](deployment.md); it is
idempotent.

## Evolution

A route the static Storybook cannot answer (a redirect, an API, a header)
goes in `apps/docs/worker/index.ts`, in front of the assets. Structural
changes (an app that uses the library, a second Worker, a data store) follow
the same contract that deployed the Storybook: add a component under `apps/`, `infra/` or
`packages/` with a `component.yaml`, land it as a pull request, and the
convergence run applies it.
