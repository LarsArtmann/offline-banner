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

## Inventory

Living doc pointers: feature inventory + evidence in `FEATURES.md`, future direction + non-goals in `ROADMAP.md`, dispatch queue in `TODO_LIST.md`, history in `CHANGELOG.md` (append-only), status snapshots under `docs/status/` (indexed by `docs/status/README.md`), plans under `docs/planning/`.

## Checks

Six flake checks (green on both systems, CI-enforced via branch protection):
- `module-contract`: unit present/absent, quickshell ExecStart, env contract, MemoryMax, ALL 22 sandbox directive lines, NoNewPrivileges absent (it strips ping's cap_net_raw), restartTriggers references the store QML, probe-overlap assertion fires on a bad config.
- `unit-verify`: systemd-analyze verify on the rendered unit (sandbox recipe: LD_PRELOAD mkdir/mkdirat shim redirects /run; --user --recursive-errors=no; graphical-session.target stubbed).
- `docs-drift`: option list derived from the module eval must appear in README + FEATURES; env-contract mention + quickstart pointers pinned.
- `shell-content`: the BUILT shell.qml must contain the namespace interpolation and the probe env markers (the unit-text contract cannot see inside the QML; negative-tested).
- `probe-transitions`: drives the REAL store QML through ok/net/link (OFFLINE_BANNER_PROBE_CMD injection, headless sway, software rendering) and asserts debounce/reason/recovery/re-arm via the state file.
- `formatting`: treefmt (nixfmt + statix).

Live evidence on record (2026-10-17, evo-x2 smoke): sandbox live-proven (ping cap_net_raw, runtime dirs, state file, ~23 MB RSS), journal + state file verified. Pixel visibility on a real monitor is NOT yet proven (session had zero active outputs) — it rides the SystemNix switch. Demo capture: `scripts/capture-demo.sh` (headless sway, ground-truth store QML); assets in `docs/assets/`.

Decision records: docs surface = README table + option descriptions + docs-drift gate (no optionDoc/manual render check — cost over value for 7 options, 2026-10-17). CI: branch protection requires the Checks workflow with admin bypass (direct pushes stay possible); dependabot weekly on the action pins; actionlint + zizmor clean (run on demand, not wired — 3-step workflow, both green).

## Consumers

- SystemNix (evo-x2) — CUTOVER DONE 2026-10-16 (owner-directed): consumed via the `offline-banner` input (locked fff0b61), thin wrapper sets `layerNamespace = "systemnix:offline-banner"`; evo-x2 eval green + shipped-QML parity proven. The hardened-unit live smoke test is DONE (2026-10-17, found+fixed the /run/user sandbox blocker) — the v3 switch is unblocked; its first real-monitor render proof rides the switch itself (the smoke session had zero active outputs).
