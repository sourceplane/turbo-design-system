# turbo-design-system — implementation plan

Three milestones, each one reviewed pull request (DE0 follows the
repository's first commit), each green before it merges.

## DE0 — the spec (DE-1)

The repository is born: `intent.yaml` with the placeholder workspace
`ws_CHANGE_ME`, `ci.yml` (byte for byte vite-react-boilerplate's,
turso-starter's but for one comment, which plans nothing until the workspace
is set), the wrangler renderer, the root workspace and turbo pipeline, the
spec index, this doc set and the task contracts.

## DE1 — the design system on Workers (DE-2)

- The template as it is: `packages/ui` (the Button, its tsup and TypeScript
  builds and exports), `packages/eslint-config` (plus `.wrangler` in its
  ignores), `packages/typescript-config`, `apps/docs` (`.storybook/main.ts`,
  the Button's story, `vite.config.ts`, its tsconfig and ESLint config),
  `.changeset`, `.npmrc`; the lockfile seeded from upstream's.
- `apps/docs/.storybook/site.ts` and `manager.ts`: the name seam and the
  theme that shows it.
- `worker/index.ts` and `wrangler.jsonc`: the Worker in front of
  `storybook-static`, `html_handling: "none"`, a directory's `index.html`, a
  404 for anything else.
- `component.yaml`: the deploy contract and its smoke over the manager, the
  preview at its own address, the stories' index, the Button's story chunk
  and a missing file.
- Tests (`tests/docs`): the Button, the stories, the seam, the Worker, the
  built Storybook and library, the licence and Changesets.
- The README's "How it maps to Vercel".

## DE2 — a baseline (DE-3)

vite-react-boilerplate's machinery, renamed: `blueprint.yaml`,
`repo-blueprint.yaml` (a module per template package, `.npmrc` and
`.changeset`), `.baseline/` (identity, product README, task contracts),
`tooling/rebrand` (the seam at `apps/docs/.storybook/site.ts`),
`tooling/bootstrap`, `tooling/catalog` (turborepo-monorepo's, which keeps a
component called `docs`), `hooks/render-deployment-docs.sh` (probing `/`,
`iframe.html`, `index.json` and each `SITE_URL`), `docs/phases/`, the context
pack, `testing/` (the leak and placement gates on this tree's files,
placement also failing on the template's name left in the Storybook or a
framework module renamed; the e2e tier building the library and the
Storybook in the stage lane's staged tree and reading every route it
promises) and `baseline.yml` / `tag.yml`.
