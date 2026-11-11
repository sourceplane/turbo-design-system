# docs

The design system's Storybook (Storybook 10 on React 19 and Vite 8, documenting the @acme/ui library, built static in docs mode and served as Cloudflare Workers + Static Assets behind one Worker, per environment)

A Cloudflare Worker with Static Assets (server rendering plus static files), deployed per environment by its CI lane.

|              |                                                                                                                    |
| ------------ | ------------------------------------------------------------------------------------------------------------------ |
| Type         | `cloudflare-workers-assets-turbo`                                                                                  |
| Source       | `apps/docs`                                                                                                        |
| Package      | `docs`                                                                                                             |
| Environments | `dev`: `verify` · `stage`: `verify`, `deploy` on a push to `main` · `prod`: `verify`, `deploy` on a push to `main` |

## Depends on

- (none)

## Depended on by

- (none)
