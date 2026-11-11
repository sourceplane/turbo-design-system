# turbo-design-system — Vercel's Design System with Turborepo template on Cloudflare Workers

**Storybook builds fully static, so the port is where it is served —
`storybook-static` as Cloudflare Workers Static Assets behind one small
Worker, every file at its own address (`iframe.html` never redirected) and a
missing file a 404, deployed by Orun to stage and prod on every merge — on
the template's own Storybook 10, React 19, Vite 8 and TypeScript 7, with the
design system's name in one module and tests of the component and its
stories the template never had; and then the baseline that makes a copy of
it somebody else's design system in one landing.**

| | |
|---|---|
| Status | ✅ Shipped (`baseline-v1`) — proven offline in Baseline CI; not yet live (risk DE-A) |
| Upstream | [vercel/turborepo](https://github.com/vercel/turborepo) `examples/design-system` (MIT), at `c30ba0a` (2026-11-10, "chore: Update design-system example (#14974)"; turborepo head `4e3bdf1`, 2026-11-11) |
| Reference | [vite-react-boilerplate](https://github.com/sourceplane/vite-react-boilerplate) — the same static Vite build behind one Worker, its tests and its bootstrap; [turborepo-monorepo](https://github.com/sourceplane/turborepo-monorepo) — a template's own Turborepo tree kept whole, an app called `docs` |
| Key | `DE` |

## Read in this order

1. [design.md](design.md) — the template, why its versions stay, how each
   Vercel piece maps to Cloudflare, serving every file at its own address,
   the name seam, the tests, the repository, and the alternative rejected.
2. [implementation-plan.md](implementation-plan.md) — the milestones and
   what each one lands.
3. [risks-and-open-questions.md](risks-and-open-questions.md) — what is not
   proven, and what was accepted.
4. [IMPLEMENTATION-STATUS.md](IMPLEMENTATION-STATUS.md) — what shipped, and
   every departure from the upstream template.

## Milestones

| Milestone | What it lands | Task |
|---|---|---|
| DE0 — the spec | the repository, its intent, CI, tooling and spec index; this doc set | DE-1 |
| DE1 — the design system on Workers | the template's library, configs and Storybook, the Storybook built static and served as assets behind one Worker, with its tests | DE-2 |
| DE2 — a baseline | the console card, the build document, the context pack and the baseline's tests | DE-3 |
