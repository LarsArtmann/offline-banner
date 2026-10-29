# offline-banner: Agent Guide

Yellow top-strip offline banner for NixOS desktops — `github:LarsArtmann/offline-banner` (public repo created and pushed 2026-10-16).

## Identity

- One NixOS module, one file: `module.nix` (`services.offline-banner`, systemd **user** service, second-Quickshell-instance pattern — Quickshell runs the inline `shell.qml`; no dependency on any bar/shell plugin).
- Extracted from SystemNix 2026-10-16 (`modules/nixos/desktop/offline-banner.nix`, deployed there as gen 904 v1 — verified 2026-10-17: SystemNix live-session report anchors `/run/current-system == 904` + `system-904-link`; gen 904 shipped v1, v2/v3 were demo-proven only and ride SystemNix's next switch). SystemNix is the origin of every behavior doctrine (non-flashing yellow, debounce, fail-visible probe, push-down animation) — the rationale comments in `module.nix` are the contract; do not silently drop them when refactoring.

## Hard rules

- **The module stays single-file and self-contained** (QML inlined via `pkgs.writeTextDir`). Extracting the QML into a store file is allowed only if the env-var contract below survives unchanged.
- **The `OFFLINE_BANNER_{INTERVAL,PROBE_HOST,PROBE_TIMEOUT,FAILURES}` env vars are a public surface** (live-tuning via drop-in, demos, the pending VM test's probe injection). Renaming them breaks live systems. The sound/history additions (2026-10-28) — `OFFLINE_BANNER_SOUND_THEME/SOUND_VOLUME/SOUNDS`, `OFFLINE_BANNER_HISTORY` — are the same contract class: unit-managed env, asserted by `module-contract`; when UNSET (bare `quickshell -p`, tests, demos) the QML keeps both features inert (silent, no home writes).
- **Never embed shell/JS parameter expansion (`${`-style) or a literal `''` in the inlined QML or check scripts** — Nix's lexer silently corrupts the former (observed 2026-10-28: `${n:-0}` in a check script rendered as `n:-0` with NO eval error) and the latter terminates the indented string outright. Escape as `''${` where a literal is truly needed; prefer POSIX-safe guards.
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

Two pnpm rules learned the hard way (2026-10-29): **any `package.json` bump must regenerate `pnpm-lock.yaml`** — CI installs with a frozen lockfile and dies on a manifest/lock mismatch (`ERR_PNPM_OUTDATED_LOCKFILE`), which is how the Website workflow sat red for two weeks. And **TypeScript stays on 6.x**: `astro check` is a CI step and refuses to run against TypeScript 7 (`astro check does not currently support TypeScript 7.0`), so a `^7` bump in devDependencies silently removes type-checking from the gate. Also drop any `minimumReleaseAgeExclude` entries pnpm auto-appends to `website/pnpm-workspace.yaml` — the repo sets no minimum release age, so they are inert noise that rots with the next bump.

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
- **Demo video**: `website/video/index.html` is the committed composition (24 s, 1920x1080; strip/bar rebuilt in CSS from module.nix colors, transform-only; lint 0 errors with 6 advisory `nested_structure_needs_subcomposition` warnings under hyperframes 0.8.214, check passed: 0 motion errors, 20/20 WCAG AA contrast); render to `website/public/demo.mp4` (<3 MB). Beat structure + verification rules: website-launch skill `references/demo-video.md`.
- **Deploy**: Firebase Hosting, shared `lars-software` project, hosting target `offline-banner` (site ID immutable). CI deploys on master push once the `FIREBASE_SERVICE_ACCOUNT` secret is set (deploy step is secret-gated so CI stays green meanwhile).
- **DNS**: applied by the owner 2026-10-17 — CNAME resolves (→ `offline-banner.web.app`, A 199.36.158.100), Firebase cert ACTIVE, both URLs serve identical content (landing + demo.mp4 verified over HTTPS the same morning). Terraform source lives in `~/projects/domains/lars.software.tf`; note `tofu init` from this host hits a GCS-backend quota error, so apply is owner-side. The custom domain itself was registered via Firebase REST API (the CLI cannot).
- **Launch posts**: Discourse + r/NixOS drafts in `docs/marketing/launch-post-drafts.md` (one narrative from the README "Why?" — do not re-invent per surface). Social preview card: `assets/branding/social-preview.png` (manual upload in repo Settings → Social preview; no API).

## Inventory

Living doc pointers: feature inventory + evidence in `FEATURES.md`, future direction + non-goals in `ROADMAP.md`, dispatch queue in `TODO_LIST.md`, history in `CHANGELOG.md` (append-only), status snapshots under `docs/status/` (indexed by `docs/status/README.md`), plans under `docs/planning/`.

## Checks

Seven flake checks (green on both systems, CI-enforced via branch protection):
- `module-contract`: unit present/absent, quickshell ExecStart, env contract (the four probe vars PLUS `SOUND_THEME/SOUND_VOLUME/SOUNDS` + `HISTORY`), pipewire in PATH with a theme on, MemoryMax, XDG_CACHE_HOME pointed at the runtime dir (specifiers DO expand in unit-file `Environment=` — verified in systemd's `config_parse_environ`), ALL sandbox directive lines (incl. the `%h/.local/state/offline-banner` home-write hole for the outage ledger), NoNewPrivileges absent (it strips ping's cap_net_raw), exactly two restartTriggers (store QML + sounds dir), probe-overlap assertion fires on a bad config.
- `unit-verify`: systemd-analyze verify on the rendered unit (sandbox recipe: LD_PRELOAD mkdir/mkdirat shim redirects /run; --user --recursive-errors=no; graphical-session.target stubbed).
- `docs-drift`: option list derived from the module eval must appear in README + FEATURES; env-contract mention + quickstart pointers pinned.
- `shell-content`: the BUILT shell.qml must contain the namespace interpolation, the probe env markers, AND the sound/history markers (`SOUND_THEME`, `SOUND_CMD`, `HISTORY`, `pw-play`) (the unit-text contract cannot see inside the QML; negative-tested) — plus the WAV gate: the full 3x4 synthesized theme/event matrix must exist as valid sub-second 44.1 kHz mono WAVs.
- `probe-transitions`: drives the REAL store QML through ok/net/link/empty-probe/demo (OFFLINE_BANNER_PROBE_CMD injection, headless sway, software rendering) and asserts debounce/reason/recovery/re-arm, the state-file freshness heartbeat, the structured journal lines (`probe failed reason=net failures=1/2`, `banner state=shown ...`), the outage ledger (one jq-validated entry per completed outage; open outages and demo never write; `state.since` set/cleared), and the sound cues via the OFFLINE_BANNER_SOUND_CMD seam (one cue per outage — shown once, recover once, NO re-sound on mid-outage reason switches, fresh outage re-sounds). CI runs it on emulated aarch64 — far slower than local — so mid-sequence asserts must tolerate extra probes: exact counter matches only at deterministic positions, regex transitions past that (`assert_journal_re`), and the heartbeat compares the state file's mtime at ns resolution (updatedAt is epoch-seconds and two 600 ms-apart probes can share a second — two same-day CI flakes, both harness races, not product bugs).
- `render-smoke`: the pixel gate — grim-captures the headless-sway output through hidden → shown → recovered via the real probe path and asserts the strip color (#f2f9e2af at 95% alpha) present on the strip, absent below it and after recovery. Software rendering (pixman); a real-monitor pixel proof still rides a live session.
- `formatting`: treefmt (nixfmt + statix).

A reference waybar consumer for the state file ships in `contrib/offline-banner-waybar` (POSIX sh + jq; emits nothing while fine, an offline widget while active, and a `stale` marker when the heartbeat exceeds `OFFLINE_BANNER_MAX_AGE`, default 15 s — not part of the module, not contract-checked).

Live evidence on record (2026-10-17, evo-x2 smoke): sandbox live-proven (ping cap_net_raw, runtime dirs, state file, ~23 MB RSS), journal + state file verified. Real-monitor pixel visibility still rides the SystemNix switch; headless pixels are CI-proven by `render-smoke`. Demo capture: `scripts/capture-demo.sh` (headless sway, ground-truth store QML, shellcheck+shfmt clean); assets in `docs/assets/`.

Decision records: docs surface = README table + option descriptions + docs-drift gate (no optionDoc/manual render check — cost over value for 7 options, 2026-10-17). CI: branch protection requires the Checks workflow with admin bypass (direct pushes stay possible); dependabot weekly on the action pins; actionlint + zizmor clean (run on demand, not wired — 3-step workflow, both green).

CI runners: the Checks job is pinned to **`ubuntu-24.04`**, not `ubuntu-latest` (2026-10-29). The label migrated to Ubuntu 26, where `qemu-user-static` has no installation candidate — the aarch64 binfmt step died in ~4 s and no nix check ran at all, twice, on an otherwise untouched tree. A red pipeline caused by a runner-image bump is invisible in the diff, so re-verify the Checks workflow whenever GitHub announces an image migration (or an aarch64 check "fails" with an apt error rather than a nix error).

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

Checklist: unit active under the full sandbox; ping works with cap_net_raw (`probe ok` for 127.0.0.1); forced outage (restart with `OFFLINE_BANNER_PROBE_HOST=192.0.2.123`) → journal `banner state=shown reason=net` + `{"active":true}` in `$XDG_RUNTIME_DIR/offline-banner/state`; demo control (`OFFLINE_BANNER_DEMO=1`) → `{"active":true,"demo":true}`; RSS well under MemoryMax; fontconfig cache warnings gone (XDG_CACHE_HOME lands in the runtime dir). Transient runs carry NO sound/history env → both stay inert; to hear the cues live, add `-p Environment="OFFLINE_BANNER_SOUND_THEME=chime"` plus `OFFLINE_BANNER_SOUNDS` pointed at the extracted store dir. `systemctl --user stop` when done — RuntimeDirectory cleans up with the unit.

### Release

1. Gates: `nix fmt && nix flake check --all-systems` green locally, CI green on master.
2. CHANGELOG: fold `[Unreleased]` into the new version, add the keep-a-changelog compare-link footer.
3. Tag + push (owner-gated): `git tag -a vX.Y.Z -m "offline-banner vX.Y.Z" && git push origin vX.Y.Z`.
4. `gh release create vX.Y.Z --verify-tag --generate-notes`, or paste the CHANGELOG section as the body.
5. Verify: CI green on the tag; `nix flake metadata github:LarsArtmann/offline-banner/vX.Y.Z` resolves.

## Consumers

- SystemNix (evo-x2) — CUTOVER DONE 2026-10-16 (owner-directed): consumed via the `offline-banner` input (locked fff0b61), thin wrapper sets `layerNamespace = "systemnix:offline-banner"`; evo-x2 eval green + shipped-QML parity proven. The hardened-unit live smoke test is DONE (2026-10-17, found+fixed the /run/user sandbox blocker) — the v3 switch is unblocked; its first real-monitor render proof rides the switch itself (the smoke session had zero active outputs).

## Git

- The auto-commit daemon commits locally every few minutes but NEVER pushes — push meaningful changes yourself. It can also commit mid-edit: check `git log` immediately before committing; if the daemon swept your files into an unpushed `chore: auto-commit` commit, `git reset --soft HEAD~1` and recommit with a real message (squash only unpushed commits).
