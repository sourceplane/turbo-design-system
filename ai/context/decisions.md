# turbo-design-system — decisions

The choices that shape this repository, one line each, with where the full
reasoning lives. Superseded decisions stay listed, marked, so the history
reads in order.

| # | Decision | Why | Source |
|---|---|---|---|
| 1 | The static Storybook served as Workers Static Assets behind one Worker; no adapter, no server rendering | Storybook renders in the browser; nothing renders at request time | design.md, "The alternative rejected" |
| 2 | The template's current Storybook 10, React 19, Vite 8 and TypeScript 7, on Node 22 and pnpm 10 | Upstream rewrote the example on 2026-11-10; every package accepts Node 22.12+, so only the floors move | design.md, "The template as it is"; risks DE-C, DE-D |
| 3 | Every file at its own address (`html_handling: "none"`); the Worker serves `/` as `index.html` and 404s the rest | The manager frames `iframe.html`; the default handling redirects it on every preview load | design.md, "Every file at its own address"; risk DE-B |
| 4 | The name is one seam, `apps/docs/.storybook/site.ts`, shown by Storybook's theme (`brandTitle`) | One place a product's identity is written; the template names itself nowhere on the page | IMPLEMENTATION-STATUS, departure 1; risk DE-G |
| 5 | Tests of the component and the stories (portable stories in jsdom), the Worker and the built output, in `tests/docs` | The template ships none | design.md, "The tests" |
| 6 | The template's release workflow dropped, Changesets kept for publishing by hand | `ci.yml` is the only push-to-main workflow | risk DE-F |
| 7 | The template's tree kept whole: `apps/docs`, `packages/ui` and its own ESLint and TypeScript packages in place of the kit's `tooling/eslint` and `tooling/tsconfig` | One ESLint and one TypeScript in the workspace; the template's layout is what its users know | design.md, "The repository" |
| 8 | One landing (`01-product`) then the record (`03-docs`); each bootstrap pull request checked in the box | A landing has a fixed cost; the convergence on main builds, deploys and smoke-tests the Storybook for real (vite-react-boilerplate) | `repo-blueprint.yaml` |
| 9 | stack-tectonic 0.19.0, not 0.20.0 | The siblings' pin; 0.20.0's lane-shared install is a layout this build has not been verified in | risk DE-E |
| 10 | Component docs are generated from the manifests and checked in CI | A hand-written copy of the component's facts drifts silently | `tooling/catalog/gen-component-docs.py` |
