# docs — runbook

## How it runs

Pull requests verify it; a merge to `main` deploys it to `stage`, `prod`.
CI plans what changed (`orun plan --changed`) and runs each lane with `orun run`;
the plan orders a component after everything it depends on.

## Local commands

```bash
pnpm --filter docs dev
pnpm --filter docs build
pnpm --filter docs lint
pnpm --filter docs preview
```

## Verify

After a deploy the lane runs this smoke against the environment it
deployed (`ORUN_ENVIRONMENT`); `DEPLOYED_URL` overrides the URL:

```bash
html=$(curl -sf "${DEPLOYED_URL}/") && echo "${html}" | grep -q './sb-manager/runtime.js' && frame=$(curl -sf "${DEPLOYED_URL}/iframe.html") && echo "${frame}" | grep -q 'id="storybook-root"' && index=$(curl -sf "${DEPLOYED_URL}/index.json") && echo "${index}" | grep -q '"button--docs"' && echo "${index}" | grep -q '"button--primary"' && main=$(echo "${frame}" | grep -oE 'assets/iframe-[A-Za-z0-9_-]+[.]js' | head -n 1) && test -n "${main}" && js=$(curl -sf "${DEPLOYED_URL}/${main}") && story=$(echo "${js}" | grep -oE 'button[.]stories-[A-Za-z0-9_-]+[.]js' | head -n 1) && test -n "${story}" && chunk=$(curl -sf "${DEPLOYED_URL}/assets/${story}") && echo "${chunk}" | grep -q 'Hello' && test "$(curl -s -o /dev/null -w '%{http_code}' "${DEPLOYED_URL}/no-such-file.js")" = 404
```

## Rollback

Revert the commit on `main`. The next convergence applies the previous desired
state; nothing was changed out of band, so there is nothing else to undo.

## Common failures

- **The smoke fails right after a first deploy**: a new workers.dev route can
  answer 4xx for a few seconds and the lane retries. A failure that persists
  is a regression in the deployed code.
