# turbo-design-system — where this repository stands

The entry page for anyone (or any agent) picking this repository up. It is
this repository's own state and does not ship to a design system built from
it; the two pages that do are [operations.md](operations.md) and
[deployment.md](deployment.md).

## What it is

Vercel's Design System with Turborepo template — the `@acme/ui` React
component library built with tsup and TypeScript, documented by Storybook 10
in docs mode — on the template's own Storybook 10, React 19, Vite 8 and
TypeScript 7, its Storybook built fully static and served as Cloudflare
Workers Static Assets behind one Worker, packaged as an Orun baseline:
`orun new --blueprint repo-blueprint.yaml` builds a new design system in its
own repository and takes it to live on stage and prod in one landing
(`01-product`), then records what went live (`03-docs`).

## Release

| | |
|---|---|
| Latest tag | `baseline-v1` — DE0–DE2: the template on Workers, and the baseline |
| Proven live | No — proven offline in Baseline CI only (risk DE-A) |

## Where to read

| Question | Page |
|---|---|
| What shipped, and every departure from upstream | `specs/epics/turbo-design-system/IMPLEMENTATION-STATUS.md` |
| Why it is built this way | [decisions.md](decisions.md), then `specs/epics/turbo-design-system/design.md` |
| What could still go wrong | [open-risks.md](open-risks.md), then `specs/epics/turbo-design-system/risks-and-open-questions.md` |
| How to instantiate it | `BOOTSTRAP.md`, `docs/phases/` |
| What each component is | `apps/docs/docs/`, `tests/docs/docs/` (generated; `python3 tooling/catalog/gen-component-docs.py`) |

## Next

1. Bootstrap one design system from `baseline-v1` from the console, and
   record its timings against the 5-minute estimate (closes DE-A).
