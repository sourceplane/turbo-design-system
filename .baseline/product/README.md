# turbo-design-system

A design system in a [Turborepo](https://turborepo.dev) monorepo — a React
component library, `@acme/ui`, built with [tsup](https://tsup.egoist.dev) and
TypeScript and documented by [Storybook](https://storybook.js.org) — with
the Storybook built fully static and served as **Cloudflare Workers + Static
Assets** behind one small Worker.

## Live deployment

<!-- 03-docs:begin -->
Not recorded yet. The bootstrap's last phase writes the live URLs, the
workspace and the secrets the Storybook uses into
[ai/context/deployment.md](ai/context/deployment.md); how it deploys and
how to operate it is in
[ai/context/operations.md](ai/context/operations.md).
<!-- 03-docs:end -->

## What is here

| Surface | Where |
|---|---|
| The component library: the Button, its tsup build and its exports | `packages/ui` |
| The Storybook: its config, the Button's story | `apps/docs/.storybook/main.ts`, `apps/docs/stories`, `apps/docs/vite.config.ts` |
| The design system's name, which the Storybook's theme shows as its title | `apps/docs/.storybook/site.ts`, `apps/docs/.storybook/manager.ts` |
| The shared ESLint and TypeScript configurations | `packages/eslint-config`, `packages/typescript-config` |
| Versioning and publishing the library (Changesets, by hand) | `.changeset/` |
| The Worker in front of the static Storybook, and the deploy contract | `apps/docs/worker/index.ts`, `apps/docs/wrangler.jsonc`, `apps/docs/component.yaml` |
| Tests of the component, the stories, the Worker and the built output | `tests/docs` (vitest, jsdom) |

## Getting started

```bash
pnpm install
pnpm check-types
pnpm lint
pnpm test             # vitest: the component, the stories and the built Storybook
pnpm build            # the library (tsup + tsc) and the Storybook → apps/docs/storybook-static
```

```bash
pnpm dev                        # the library in watch mode and Storybook on http://localhost:6006
pnpm --filter docs preview      # wrangler dev over the built Storybook, as the Worker serves it
```

Add a component in `packages/ui/src`, give it an entry in
`packages/ui/tsup.config.ts` and an export in `packages/ui/package.json`, and
write its story in `apps/docs/stories`: the Storybook imports the library's
built exports, as any app that uses it would. The design system's name is in
`apps/docs/.storybook/site.ts`.

## How it deploys

Merges to `main` converge through [Orun](https://github.com/sourceplane/orun):
`.github/workflows/ci.yml` plans the changed components and runs each lane
against the workspace in `intent.yaml`. The Storybook deploys to `stage`, then
to `prod` once stage has converged on the same commit; `dev` only verifies.
The Worker is `turbo-design-system-docs-<env>` on your account's workers.dev
subdomain, and every deploy is smoke-tested over HTTP: the home page must be
Storybook's manager, its preview (`iframe.html`) must answer at its own
address, the stories' index must list the Button's docs page and story, the
preview's bundle must load the Button's story, and a missing file must be a
404. A pull request runs the same pipeline's verify lanes: the Storybook
built and dry-deployed for each environment, with nothing deployed. They do
not lint or run the tests, so run `pnpm check-types`, `pnpm lint` and
`pnpm test` before you push. (A push to `main` builds, deploys and
smoke-tests.)

The pipeline holds one credential, GitHub's own `GITHUB_TOKEN`. The
Cloudflare token and account id are brokered per run from the workspace's
Cloudflare connection; nothing provider-shaped is stored in the repository
or in GitHub.

**Deploy by hand.** Orunbase's **Deploy** button on a component, or **Run
workflow** on the CI workflow in GitHub's Actions tab (on `main`), runs
`ci.yml` for the environment and components you pick, and each one deploys
exactly as a merge would deploy it. Leave the component blank to redeploy
every component in that environment, with nothing changed: after rotating a
secret, say. A component with nothing to run in that environment (a test
suite in `prod`) is left out with a notice.

**Publishing the library.** No workflow publishes to npm. To publish
`@acme/ui`, replace the `@acme` scope with one you own, run `pnpm changeset`,
then `pnpm version-packages` and `pnpm release` with an npm token in your
environment.

## Custom domain

The Storybook answers on workers.dev from its first deploy. To serve it on
your own domain:

1. Add the domain to the Cloudflare account the Storybook deploys into, and
   attach it to the Worker (dashboard → Workers & Pages →
   `turbo-design-system-docs-prod` → Settings → Domains & Routes → Add →
   Custom domain). Do the same for stage with a subdomain if you want one.
2. Record the environment's public origin in `intent.yaml`. The Storybook
   writes no absolute URL, so the build does not change; the deployment
   record probes the domain beside the workers.dev URL:

   ```yaml
   environments:
     prod:
       env:
         SITE_URL: https://turbo-design-system.example.com
   ```

   The design system was born with the reserved placeholder
   `turbo-design-system.example.com` where its domain goes: that example,
   and `BASE_DOMAIN` under each environment (dev, stage and prod) in
   `intent.yaml`. Replace it with your domain in the same change.

## Credits

The design system is Vercel's Turborepo example
([vercel/turborepo](https://github.com/vercel/turborepo),
`examples/design-system`, © 2026 Vercel, MIT-licensed —
`apps/docs/LICENSE.md` and `packages/*/LICENSE.md`). Its Button is the
template's placeholder component; replace it with your own as you make the
design system yours.
