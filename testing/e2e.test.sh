#!/usr/bin/env bash
# TIER 2 — the site a bootstrap produces builds, deploys (dry) and serves.
#
# placement.test.sh proves the tree a bootstrap ends with is the right tree.
# This proves it WORKS, by doing to it what its own pipelines will:
#
#   1. at the finished site, the landing's own checks — install with the
#      lockfile the site ships, check-types, lint, test, build. The
#      bootstrap's own landings are checked in the box with `orun validate`
#      and `orun plan` alone (`checks: local`; their PR's CI on an
#      `orun/BASE-…` branch is `plan` alone, and the convergence on main
#      builds, deploys and smoke-tests the site), so THIS is where a site
#      those steps refuse is caught: before the tag, not after a build has
#      merged it. Every later pull request of the site runs ci.yml's verify
#      lanes;
#   2. the stage lane's own steps, rendered by `orun plan` in the site: on a
#      pull request (the verify profile) `verify-app-structure`, `build-app` —
#      the component's buildCommand (`turbo run build --filter=docs`: the
#      library with tsup and tsc, then `storybook build --docs`), the same
#      step the deploy profile runs — `verify-build-output` and
#      `deploy-dry-run` (`wrangler deploy --dry-run` as
#      <reponame>-docs-stage). They run IN THE TREE THE RUNNER STAGES for the
#      job (testing/lib/stage-job.py), with the dependency layout the pinned
#      composition produces: if its install step is `scope: lane`, the
#      top-level node_modules is a symlink to the source checkout's; if not,
#      the job's own install step runs inside the staged tree. The staged
#      build must have written its OWN library and Storybook — the source
#      tree's build output is removed before staging, as a CI checkout has
#      none — the manager, the preview, the stories' index, the Button story,
#      and the design system's name in the manager's bundle;
#   3. serve the built Worker with `wrangler dev` and run the component's OWN
#      `smokeCommand` against it, verbatim — the check the real deploy ends
#      with — and then read every route the Storybook promises: the manager
#      at / (and its own address, and a docs page's query), its runtime and
#      addon bundles, the preview at iframe.html with no redirect and every
#      bundle it loads, the stories' index, the project file, the favicon
#      and the fonts with their types, the design system's name in the
#      manager's bundle, the template's Button story in its chunk — and no
#      redirect anywhere, and a 404 for every address that is not a file.
#
# What it cannot do is the platform's half: create the repository, mint the
# brokered Cloudflare token, deploy for real and probe workers.dev. That is a
# bootstrap against a workspace (BOOTSTRAP.md); everything short of it is here.
#
# Needs: orun, node, pnpm, python3 (+PyYAML), git, curl, and the network for
# `pnpm install` (or a warm store). A few minutes: two installs and builds
# (the landing's checks over the site, and the stage lane's own in its staged
# tree).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
# shellcheck source=lib/bootstrap.sh
source "$here/lib/bootstrap.sh"

for bin in orun node pnpm python3 git curl; do
  command -v "$bin" >/dev/null || { echo "e2e.test.sh needs $bin on PATH" >&2; exit 1; }
done

scratch="$(mktemp -d)"
dev_pid=""
# wrangler dev runs under pnpm, node and two workerd processes; a TERM to the
# first does not reach the rest, and waiting on it then never returns. So it is
# started as its own process group (setsid) and the whole group is stopped.
cleanup() {
  if [ -n "$dev_pid" ]; then
    kill -TERM -- "-$dev_pid" 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do kill -0 -- "-$dev_pid" 2>/dev/null || break; sleep 0.5; done
    kill -KILL -- "-$dev_pid" 2>/dev/null || true
  fi
  rm -rf "$scratch"
}
trap cleanup EXIT
values="$here/fixtures/acme.json"
repo="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['reponame'])" "$values")"
export CI=1 WRANGLER_SEND_METRICS=false TURBO_TELEMETRY_DISABLED=1

# The landing's own checks, step for step, run here at once on the whole
# tree. A pull request in the site builds and dry-deploys it through ci.yml's
# lanes; the lint and the tests run here, and by hand before a push.
LANDING_CHECKS=(
  "pnpm install --frozen-lockfile"
  "pnpm check-types"
  "pnpm lint"
  "pnpm test"
  "pnpm build"
)
checks() { # DIR LOG
  local dir="$1" log="$2" cmd
  for cmd in "${LANDING_CHECKS[@]}"; do
    echo "   \$ $cmd" | tee -a "$log"
    if ! (cd "$dir" && bash -c "$cmd") >> "$log" 2>&1; then
      echo "FAIL: \`$cmd\` failed in $dir" >&2; tail -40 "$log" >&2; return 1
    fi
  done
}

echo "── the offline bootstrap (testing/lib/bootstrap.sh)"
tree="$scratch/$repo"
bootstrap_offline "$root" "$tree" "$values" "$scratch/logs" > "$scratch/bootstrap.log" 2>&1 || {
  echo "FAIL: the offline bootstrap stopped" >&2; tail -40 "$scratch/bootstrap.log" >&2; exit 1; }
echo "   2 phases placed and landed"

# ── 1. the finished site ───────────────────────────────────────────────────
echo "── the finished site: install, check-types, lint, test, build"
checks "$tree" "$scratch/checks-site.log"

# ── 2. the deploy lane's steps, for stage ──────────────────────────────────
echo "── the stage lane: verify-app-structure, build-app, verify-build-output, deploy-dry-run"
# The 01-product landing over the repository's empty first commit: every file
# of the site changed, as on its pull request.
s00="$(git -C "$tree" rev-parse HEAD~2)"; s01="$(git -C "$tree" rev-parse HEAD~1)"
(cd "$tree" && orun plan --intent intent.yaml --trigger github-pull-request --changed \
   --base "$s00" --head "$s01" --env stage --output "$scratch/plan.json") > "$scratch/plan.log" 2>&1 \
  || { echo "FAIL: orun plan" >&2; tail -15 "$scratch/plan.log" >&2; exit 1; }
python3 - "$scratch/plan.json" "$scratch/steps" <<'PY'
import json, pathlib, sys
plan = json.load(open(sys.argv[1]))
out = pathlib.Path(sys.argv[2]); out.mkdir()
job = next(j for j in plan["jobs"] if j["component"] == "docs" and j["environment"] == "stage")
for s in job["steps"]:
    if s["id"] in ("verify-app-structure", "build-app", "verify-build-output", "deploy-dry-run"):
        (out / f"{s['id']}.sh").write_text(s.get("run") or "")
    if s["id"] == "install-workspace-dependencies":
        (out / "install.sh").write_text(s.get("run") or "")
        (out / "install.wd").write_text(s.get("working-directory") or ".")
        (out / "install.scope").write_text(s.get("scope") or "job")
(out / "path").write_text(job.get("path") or "apps/docs")
for k, v in (job.get("env") or {}).items():
    (out / "env").open("a").write(f"export {k}={json.dumps(v)}\n")
PY
# The job's private tree, staged as orun stages it. The source checkout
# carries no build output (a CI checkout has none, so the plain-tree build's is
# removed rather than copied in), and its dependencies are what the pinned
# composition says: a lane-scoped install ran once in the source tree (step 1
# ran the same command) and is linked in, or the job installs its own.
rm -rf "$tree/apps/docs/storybook-static" "$tree/apps/docs/.wrangler" "$tree/packages/ui/dist"
work="$tree/.orun/runs/e2e/docs.stage.verify-deploy/work"
[ -f "$scratch/steps/install.sh" ] || { echo "FAIL: the stage lane has no install step" >&2; exit 1; }
if [ "$(cat "$scratch/steps/install.scope")" = lane ]; then
  python3 "$here/lib/stage-job.py" "$tree" "$work" --shared-deps
  [ -L "$work/node_modules" ] || { echo "FAIL: the staged tree's node_modules is not the lane's symlink" >&2; exit 1; }
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: lane — node_modules → the source tree's"
else
  python3 "$here/lib/stage-job.py" "$tree" "$work"
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: job — installing inside it"
  echo "   ▸ install-workspace-dependencies"
  (cd "$work/$(cat "$scratch/steps/path")/$(cat "$scratch/steps/install.wd")" && bash -e "$scratch/steps/install.sh") \
    > "$scratch/install.log" 2>&1 || { echo "FAIL: the lane's install step" >&2; tail -30 "$scratch/install.log" >&2; exit 1; }
  [ -d "$work/node_modules" ] && [ ! -L "$work/node_modules" ] \
    || { echo "FAIL: the job's install did not land inside its own tree" >&2; exit 1; }
fi
for step in verify-app-structure build-app verify-build-output deploy-dry-run; do
  [ -f "$scratch/steps/$step.sh" ] || { echo "FAIL: the stage verify lane has no $step step" >&2; exit 1; }
  echo "   ▸ $step"
  # The runner's per-job environment: the job's env (intent environment
  # `env:`) and ORUN_ENVIRONMENT; the step runs in the component's directory.
  if ! (cd "$work/$(cat "$scratch/steps/path")" && \
        { [ -f "$scratch/steps/env" ] && source "$scratch/steps/env"; true; } && \
        export ORUN_ENVIRONMENT=stage && bash -e "$scratch/steps/$step.sh") > "$scratch/$step.log" 2>&1; then
    echo "FAIL: the deploy lane's $step step" >&2; tail -40 "$scratch/$step.log" >&2; exit 1
  fi
done
# What the staged build must have been: the library by tsup and tsc, then
# Storybook's docs-mode build, writing a Storybook of its own (the source
# tree's was removed): the manager and the preview, the stories' index built
# from the staged library, the design system's name in the manager's bundle,
# and the Button story in its chunk.
grep -q 'Storybook build completed successfully' "$scratch/build-app.log" \
  || { echo "FAIL: the staged build is not Storybook's" >&2; tail -20 "$scratch/build-app.log" >&2; exit 1; }
python3 - "$work" "$values" <<'PY' || exit 1
import json, pathlib, re, sys
work, values = pathlib.Path(sys.argv[1]), json.load(open(sys.argv[2]))
name = values["productname"]
out, ui = work / "apps/docs/storybook-static", work / "packages/ui/dist"
for f in ("button.js", "button.mjs", "button.d.ts"):
    if not (ui / f).is_file():
        sys.exit(f"FAIL: the staged build did not write the library's {f}")
manager = (out / "index.html").read_text() if (out / "index.html").is_file() else ""
preview = (out / "iframe.html").read_text() if (out / "iframe.html").is_file() else ""
if "./sb-manager/runtime.js" not in manager:
    sys.exit("FAIL: the staged build has no Storybook manager")
if 'id="storybook-root"' not in preview:
    sys.exit("FAIL: the staged build has no Storybook preview")
index = json.loads((out / "index.json").read_text())
entries = index.get("entries") or {}
if set(entries) != {"button--docs", "button--primary"}:
    sys.exit(f"FAIL: the stories' index is {sorted(entries)}, not the button's docs page and story")
if entries["button--primary"].get("componentPath") != "../../packages/ui/dist/button.mjs":
    sys.exit(f"FAIL: the story documents {entries['button--primary'].get('componentPath')}, not the built library")
bundles = re.findall(r"import '\./(sb-addons/[^']+/manager-bundle\.js)'", manager)
if not any(json.dumps(name) in (out / b).read_text() for b in bundles):
    sys.exit(f"FAIL: no manager bundle carries the design system's name {name!r}")
main = re.search(r'src="\./(assets/iframe-[A-Za-z0-9_-]+\.js)"', preview)
chunk = main and re.search(r"\./(button\.stories-[A-Za-z0-9_-]+\.js)", (out / main.group(1)).read_text())
if not chunk or "Hello" not in (out / "assets" / chunk.group(1)).read_text():
    sys.exit("FAIL: the preview does not load the Button story")
print(f"   the staged build wrote its own library and Storybook: {len(bundles)} manager bundles, the name {name!r}, "
      f"the stories' index and assets/{chunk.group(1)}")
PY

# What the deploy would upload: the Worker bundled from its source entry, and
# the static build beside it as assets.
grep -q 'Total Upload' "$scratch/deploy-dry-run.log" || { echo "FAIL: the dry run listed no Worker upload" >&2; tail -20 "$scratch/deploy-dry-run.log" >&2; exit 1; }
grep -m1 'Total Upload' "$scratch/deploy-dry-run.log" | sed 's/^/   /'
cfg="$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['spec']['parameters']['wranglerConfig'])" "$tree/apps/docs/component.yaml")"

# ── 3. serve it, and smoke it as the deploy does ───────────────────────────
echo "── wrangler dev over the built Worker ($cfg)"
port=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")
(cd "$work/apps/docs" && exec setsid pnpm exec wrangler dev --config "$cfg" --ip 127.0.0.1 --port "$port" \
   --name "$repo-docs-stage" --show-interactive-dev-session=false) > "$scratch/dev.log" 2>&1 < /dev/null &
dev_pid=$!
url="http://127.0.0.1:$port"
for _ in $(seq 1 90); do
  curl -s -o /dev/null "$url/" && break
  kill -0 "$dev_pid" 2>/dev/null || { echo "FAIL: wrangler dev exited" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }
  sleep 1
done
curl -s -o /dev/null "$url/" || { echo "FAIL: wrangler dev never answered" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }

echo "   ▸ the component's own smokeCommand, DEPLOYED_URL=$url"
smoke="$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['spec']['parameters']['smokeCommand'])" "$tree/apps/docs/component.yaml")"
DEPLOYED_URL="$url" bash -c "$smoke" || { echo "FAIL: the deploy's smoke refused the site" >&2; exit 1; }

echo "   ▸ every route the Storybook promises"
python3 - "$url" "$values" <<'PY'
import json, re, sys, urllib.error, urllib.parse, urllib.request
base, values = sys.argv[1], json.load(open(sys.argv[2]))
name = values["productname"]
problems = []
def bad(m): problems.append(m)
class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k): return None
opener = urllib.request.build_opener(NoRedirect)
NAV = {"Sec-Fetch-Mode": "navigate", "Sec-Fetch-Dest": "document", "Accept": "text/html"}
def get(path, nav=False, method="GET"):
    req = urllib.request.Request(urllib.parse.urljoin(base + "/", path), headers=NAV if nav else {}, method=method)
    try:
        with opener.open(req, timeout=30) as r:
            return r.status, r.headers, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.headers, e.read()
def ctype(h):
    return (h.get("content-type") or "").split(";")[0].strip()
TYPES = {".js": "text/javascript", ".css": "text/css", ".svg": "image/svg+xml", ".json": "application/json",
         ".woff2": "font/woff2", ".html": "text/html"}
def want_file(path, nav=False):
    s, h, b = get(path, nav=nav)
    last = path.split("?")[0].rsplit("/", 1)[-1]
    ext = last[last.rindex("."):] if "." in last else ".html"
    if s != 200 or ctype(h) != TYPES[ext]:
        bad(f"{path} answered {s} {ctype(h)}, not 200 {TYPES[ext]}")
    return b.decode(errors="replace")

# The manager: at /, at its own address, and with a docs page or a story in
# its query (Storybook's every page), with a browser's navigation headers or
# without.
manager = want_file("/", nav=True)
for path in ("/index.html", "/?path=/docs/button--docs", "/?path=/story/button--primary"):
    for nav in (True, False):
        if want_file(path, nav=nav) != manager:
            bad(f"{path} ({'navigation' if nav else 'no navigation headers'}) is not the manager")
for want in ('<link rel="icon" type="image/svg+xml" href="./favicon.svg" />', "./sb-manager/runtime.js"):
    if want not in manager:
        bad(f"the manager does not carry {want!r}")
bundles = re.findall(r"import '\./(sb-addons/[^']+/manager-bundle\.js)'", manager)
if len(bundles) < 3:
    bad(f"the manager loads {bundles}, not the addons' bundles")
texts = {b: want_file(f"/{b}") for b in ["sb-manager/runtime.js", *bundles]}
if not any(json.dumps(name) in t for t in texts.values()):
    bad(f"no manager bundle carries the design system's name {name!r}")
for font in sorted(set(re.findall(r"\./(sb-common-assets/[a-z-]+\.woff2)", manager))):
    want_file(f"/{font}")
want_file("/favicon.svg")

# The preview at its own address (no redirect to /iframe), with a story's
# or a docs page's query, and every bundle it loads.
preview = want_file("/iframe.html")
if 'id="storybook-root"' not in preview:
    bad("iframe.html is not Storybook's preview")
for q in ("?id=button--primary&viewMode=story", "?id=button--docs&viewMode=docs"):
    if want_file(f"/iframe.html{q}") != preview:
        bad(f"/iframe.html{q} is not the preview")
loads = re.findall(r'<(?:script|link)[^>]+(?:src|href)="\./([^"]+)"', preview)
if not loads:
    bad("the preview loads no bundle")
main = ""
for n in loads:
    body = want_file(f"/{n}")
    if re.fullmatch(r"assets/iframe-[A-Za-z0-9_-]+\.js", n):
        main = body
chunk = re.search(r"\./(button\.stories-[A-Za-z0-9_-]+\.js)", main)
story = want_file(f"/assets/{chunk.group(1)}") if chunk else ""
for want in ("Hello", "1px solid gray", "radio"):
    if want not in story:
        bad(f"the Button story's chunk does not carry the template's {want!r}")

# The stories' index and the project file.
try:
    index = json.loads(want_file("/index.json"))
    if set(index.get("entries") or {}) != {"button--docs", "button--primary"}:
        bad(f"/index.json indexes {sorted(index.get('entries') or {})}")
    json.loads(want_file("/project.json"))
except ValueError as e:
    bad(f"the index or the project file is not JSON: {e}")

s, h, _ = get("/", method="HEAD")
if s != 200:
    bad(f"HEAD / answered {s}")

# Nothing of the baseline's own name, and a 404 for every address that is
# not a file: Storybook keeps its pages in the query, so none is a page.
if "turbo-design-system-docs" in manager or any("turbo-design-system-docs" in t for t in texts.values()):
    bad("the Storybook still carries the baseline's Worker name")
if name != "Design System" and any('"Design System"' in t for t in texts.values()):
    bad("a manager bundle still carries the template's name")
for path in ("/no-such-file.js", "/assets/missing.png", "/iframe", "/no/such/page", "/sb-manager/", "/docs/button--docs"):
    for nav in (True, False):
        s, h, b = get(path, nav=nav)
        if s != 404:
            bad(f"{path} ({'navigation' if nav else 'no navigation headers'}) answered {s}, not a 404")

if problems:
    for p in problems:
        print(f"  ✕ {p}", file=sys.stderr)
    sys.exit(1)
print(f"   the manager (/, /index.html, a docs page's query), {len(texts)} manager bundles, the fonts and favicon, "
      f"the preview at iframe.html with {len(loads)} bundles, the Button story's chunk, the stories' index and the "
      f"project file, all with their types and no redirect; the name {name!r} in the manager; 404s off the files")
PY

echo "e2e.test.sh: ok"
