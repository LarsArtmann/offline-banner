# offline-banner: Agent Guide

Yellow top-strip offline banner for NixOS desktops — `github:LarsArtmann/offline-banner` (public repo created and pushed 2026-10-16).

## Identity

- One NixOS module, one file: `module.nix` (`services.offline-banner`, systemd **user** service, second-Quickshell-instance pattern — Quickshell runs the inline `shell.qml`; no dependency on any bar/shell plugin).
- Extracted from SystemNix 2026-10-16 (`modules/nixos/desktop/offline-banner.nix`, deployed there as gen 904 v1 — verified 2026-10-17: SystemNix live-session report anchors `/run/current-system == 904` + `system-904-link`; gen 904 shipped v1, v2/v3 were demo-proven only and ride SystemNix's next switch). SystemNix is the origin of every behavior doctrine (non-flashing yellow, debounce, fail-visible probe, push-down animation) — the rationale comments in `module.nix` are the contract; do not silently drop them when refactoring.

## Hard rules

- **The module stays single-file and self-contained** (QML inlined via `pkgs.writeTextDir`). Extracting the QML into a store file is allowed only if the env-var contract below survives unchanged.
- **The `OFFLINE_BANNER_{INTERVAL,PROBE_HOST,PROBE_TIMEOUT,FAILURES}` env vars are a public surface** (live-tuning via drop-in, demos, the pending VM test's probe injection). Renaming them breaks live systems.
- **Nix '' string escaping**: the QML lives inside a Nix indented string — `\"` sequences in the probe JS are literal and required; there must be no `${` in QML/JS except intended Nix interpolations (`${cfg.layerNamespace}`).
- 2-space indentation; `nix fmt` (treefmt: nixfmt + statix) is the ONLY style arbiter and covers `.nix` only. Markdown is hand-formatted by deliberate decision (2026-10-17): status/planning docs are point-in-time snapshots, never machine-reflowed; no dprint.json in this repo (dropped as an uninvoked split brain — readopt only via a real BuildFlow `.buildflow.yml`, which regenerates its own config).
- `probeTimeoutSeconds < checkIntervalSeconds` is an eval-time assertion — keep it.

## Commands

```bash
nix flake check   # formatting + module-contract checks (eval + trivial builds)
nix fmt           # treefmt wrapper (flake formatter)
```

Website (Astro + Starlight + Tailwind v4, pnpm pinned via packageManager):

```bash
cd website && nix shell nixpkgs#nodejs -c pnpm install
cd website && nix shell nixpkgs#nodejs -c pnpm run build   # astro build + fix-csp.mjs
cd website && nix shell nixpkgs#nodejs -c pnpm exec astro check && nix shell nixpkgs#nodejs -c pnpm exec html-validate "dist/**/*.html"
cd website && nix shell nixpkgs#nodejs nixpkgs#firebase-tools -c firebase deploy --only hosting:offline-banner --project lars-software
```

Promo video (HyperFrames; NixOS needs real node + chrome libs — never bare npx):

```bash
cd website/video
bash ~/projects/SKILLS/scripts/hf-env.sh --install .   # first time only
bash ~/projects/SKILLS/scripts/hf-env.sh -- node node_modules/hyperframes/bin/hyperframes.mjs lint
bash ~/projects/SKILLS/scripts/hf-env.sh -- node node_modules/hyperframes/bin/hyperframes.mjs check
bash ~/projects/SKILLS/scripts/hf-env.sh -- node node_modules/hyperframes/bin/hyperframes.mjs render --quality high --output ../public/demo.mp4
```

## Public presence

- **Website**: https://offline-banner.lars.software (canonical) = https://offline-banner.web.app (live alias). Source in `website/` (gogenfilter baseline; banner-yellow `#e8d44d` accent on the demo's catppuccin-dark base; og:image = 1200x630 crop of the video poster). Landing video anchor `#demo` is deep-linked from the README bar.
- **Demo video**: `website/video/index.html` is the committed composition (24 s, 1920x1080; strip/bar rebuilt in CSS from module.nix colors, transform-only, lint+check clean); render to `website/public/demo.mp4` (<3 MB). Beat structure + verification rules: website-launch skill `references/demo-video.md`.
- **Deploy**: Firebase Hosting, shared `lars-software` project, hosting target `offline-banner` (site ID immutable). CI deploys on master push once the `FIREBASE_SERVICE_ACCOUNT` secret is set (deploy step is secret-gated so CI stays green meanwhile).
- **DNS**: `offline-banner.lars.software` CNAME + ACME TXT staged in `~/projects/domains/lars.software.tf`; `tofu apply` is owner-gated (host gcloud identity lacks GCS-backend quota access). Custom domain registered at Firebase (REST API; the CLI cannot) — CERT_ACTIVE follows 10-60 min after apply.
- **Launch posts**: Discourse + r/NixOS drafts in `docs/marketing/launch-post-drafts.md` (one narrative from the README "Why?" — do not re-invent per surface). Social preview card: `assets/branding/social-preview.png` (manual upload in repo Settings → Social preview; no API).

## Inventory

Living doc pointers: feature inventory + evidence in `FEATURES.md`, future direction + non-goals in `ROADMAP.md`, dispatch queue in `TODO_LIST.md`, history in `CHANGELOG.md` (append-only), status snapshots under `docs/status/` (indexed by `docs/status/README.md`), plans under `docs/planning/`.

## Checks

Seven flake checks (green on both systems, CI-enforced via branch protection):
- `module-contract`: unit present/absent, quickshell ExecStart, env contract, MemoryMax, XDG_CACHE_HOME pointed at the runtime dir (specifiers DO expand in unit-file `Environment=` — verified in systemd's `config_parse_environ`), ALL 22 sandbox directive lines, NoNewPrivileges absent (it strips ping's cap_net_raw), restartTriggers references the store QML, probe-overlap assertion fires on a bad config.
- `unit-verify`: systemd-analyze verify on the rendered unit (sandbox recipe: LD_PRELOAD mkdir/mkdirat shim redirects /run; --user --recursive-errors=no; graphical-session.target stubbed).
- `docs-drift`: option list derived from the module eval must appear in README + FEATURES; env-contract mention + quickstart pointers pinned.
- `shell-content`: the BUILT shell.qml must contain the namespace interpolation and the probe env markers (the unit-text contract cannot see inside the QML; negative-tested).
- `probe-transitions`: drives the REAL store QML through ok/net/link/empty-probe/demo (OFFLINE_BANNER_PROBE_CMD injection, headless sway, software rendering) and asserts debounce/reason/recovery/re-arm, the state-file freshness heartbeat, AND the structured journal lines (`probe failed reason=net failures=1/2`, `banner state=shown ...`).
- `render-smoke`: the pixel gate — grim-captures the headless-sway output through hidden → shown → recovered via the real probe path and asserts the strip color (#f2f9e2af at 95% alpha) present on the strip, absent below it and after recovery. Software rendering (pixman); a real-monitor pixel proof still rides a live session.
- `formatting`: treefmt (nixfmt + statix).

A reference waybar consumer for the state file ships in `contrib/offline-banner-waybar` (POSIX sh + jq; emits nothing while fine, an offline widget while active, and a `stale` marker when the heartbeat exceeds `OFFLINE_BANNER_MAX_AGE`, default 15 s — not part of the module, not contract-checked).

Live evidence on record (2026-10-17, evo-x2 smoke): sandbox live-proven (ping cap_net_raw, runtime dirs, state file, ~23 MB RSS), journal + state file verified. Real-monitor pixel visibility still rides the SystemNix switch; headless pixels are CI-proven by `render-smoke`. Demo capture: `scripts/capture-demo.sh` (headless sway, ground-truth store QML, shellcheck+shfmt clean); assets in `docs/assets/`.

Decision records: docs surface = README table + option descriptions + docs-drift gate (no optionDoc/manual render check — cost over value for 7 options, 2026-10-17). CI: branch protection requires the Checks workflow with admin bypass (direct pushes stay possible); dependabot weekly on the action pins; actionlint + zizmor clean (run on demand, not wired — 3-step workflow, both green).

## Runbooks

### Live smoke test (hardened unit without a NixOS switch)

Runs the exact serviceConfig sandbox as a transient user unit. Bus-transient properties do NOT expand specifiers (the `%t` expansion above is unit-file-only), so runtime paths are literal. Ground-truth store QML dir: extract exactly as `scripts/capture-demo.sh` does (third word of the eval'd `ExecStart`).

```bash
uid=$(id -u)
systemd-run --user --unit=offline-banner-smoke \
  -p ProtectSystem=strict -p ProtectHome=read-only -p PrivateTmp=true \
  -p RuntimeDirectory="offline-banner quickshell" -p RuntimeDirectoryMode=0700 \
  -p ReadWritePaths="/run/user/$uid/offline-banner /run/user/$uid/quickshell" \
  -p MemoryMax=256M \
  -p Environment="OFFLINE_BANNER_PROBE_HOST=127.0.0.1" \
  -- quickshell -p "$qml"
```

Checklist: unit active under the full sandbox; ping works with cap_net_raw (`probe ok` for 127.0.0.1); forced outage (restart with `OFFLINE_BANNER_PROBE_HOST=192.0.2.123`) → journal `banner state=shown reason=net` + `{"active":true}` in `$XDG_RUNTIME_DIR/offline-banner/state`; demo control (`OFFLINE_BANNER_DEMO=1`) → `{"active":true,"demo":true}`; RSS well under MemoryMax; fontconfig cache warnings gone (XDG_CACHE_HOME lands in the runtime dir). `systemctl --user stop` when done — RuntimeDirectory cleans up with the unit.

### Release

1. Gates: `nix fmt && nix flake check --all-systems` green locally, CI green on master.
2. CHANGELOG: fold `[Unreleased]` into the new version, add the keep-a-changelog compare-link footer.
3. Tag + push (owner-gated): `git tag -a vX.Y.Z -m "offline-banner vX.Y.Z" && git push origin vX.Y.Z`.
4. `gh release create vX.Y.Z --verify-tag --generate-notes`, or paste the CHANGELOG section as the body.
5. Verify: CI green on the tag; `nix flake metadata github:LarsArtmann/offline-banner/vX.Y.Z` resolves.

## Consumers

- SystemNix (evo-x2) — CUTOVER DONE 2026-10-16 (owner-directed): consumed via the `offline-banner` input (locked fff0b61), thin wrapper sets `layerNamespace = "systemnix:offline-banner"`; evo-x2 eval green + shipped-QML parity proven. The hardened-unit live smoke test is DONE (2026-10-17, found+fixed the /run/user sandbox blocker) — the v3 switch is unblocked; its first real-monitor render proof rides the switch itself (the smoke session had zero active outputs).
