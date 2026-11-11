# docs — architecture

Built by the turbo pipeline from `apps/docs` and deployed with wrangler.

|                     |                                                 |
| ------------------- | ----------------------------------------------- |
| Worker config       | `apps/docs/wrangler.jsonc`                      |
| Entry               | `./worker/index.ts`                             |
| Compatibility date  | `2026-10-01`                                    |
| Compatibility flags | `nodejs_compat`, `global_fetch_strictly_public` |

## Bindings

| Binding  | Kind          | Source               |
| -------- | ------------- | -------------------- |
| `ASSETS` | Static assets | `./storybook-static` |
