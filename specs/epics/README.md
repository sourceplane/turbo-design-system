# Epics

Orun-style work programs. Each epic is a folder carrying `epic.yaml` (the
declaration the platform reads: slug, key prefix, milestones with exit
criteria and task keys) beside its doc set. The pull request that adds the
folder is the adoption; the merge creates the epic in the workspace.

| Epic | Cluster | Status | What it is |
|------|---------|--------|------------|
| [`turbo-design-system/`](./turbo-design-system/) | **DE** | ✅ Shipped (`baseline-v1`); not yet live | Vercel's Design System with Turborepo template — the @acme/ui React library built with tsup, documented by Storybook 10 in docs mode — the Storybook built static and served as Cloudflare Workers Static Assets behind one Worker, and an Orun baseline that instantiates it (DE2) |

As-built ≠ intent: what shipped lives in each epic's `IMPLEMENTATION-STATUS.md`.
