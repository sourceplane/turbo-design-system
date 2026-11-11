# docs-tests

The design system's vitest suite (the Button component and the template's stories run as portable stories in jsdom, the name seam and the Storybook theme that reads it, the Worker's routing and its assets config, the built Storybook and the built library, the licence), run with pnpm test

The test suite for **docs**. It deploys nothing: its lane installs, builds and runs the tests.

|              |                      |
| ------------ | -------------------- |
| Type         | `turbo-package`      |
| Source       | `tests/docs`         |
| Package      | `@repo/docs-tests`   |
| Environments | `dev`: `quick-check` |

## Depends on

- (none)

## Depended on by

- (none)
