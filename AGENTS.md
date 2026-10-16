# offline-banner: Agent Guide

Yellow top-strip offline banner for NixOS desktops — `github:LarsArtmann/offline-banner` (public repo created and pushed 2026-10-16).

## Identity

- One NixOS module, one file: `module.nix` (`services.offline-banner`, systemd **user** service, second-Quickshell-instance pattern — Quickshell runs the inline `shell.qml`; no dependency on any bar/shell plugin).
- Extracted from SystemNix 2026-10-16 (`modules/nixos/desktop/offline-banner.nix`, deployed there as gen 904). SystemNix is the origin of every behavior doctrine (non-flashing yellow, debounce, fail-visible probe, push-down animation) — the rationale comments in `module.nix` are the contract; do not silently drop them when refactoring.

## Hard rules

- **The module stays single-file and self-contained** (QML inlined via `pkgs.writeTextDir`). Extracting the QML into a store file is allowed only if the env-var contract below survives unchanged.
- **The `OFFLINE_BANNER_{INTERVAL,PROBE_HOST,PROBE_TIMEOUT,FAILURES}` env vars are a public surface** (live-tuning via drop-in, demos, the pending VM test's probe injection). Renaming them breaks live systems.
- **Nix '' string escaping**: the QML lives inside a Nix indented string — `\"` sequences in the probe JS are literal and required; there must be no `${` in QML/JS except intended Nix interpolations (`${cfg.layerNamespace}`).
- 2-space indentation, `nix fmt` (treefmt: nixfmt + statix) is the only style arbiter (a root `dprint.json` for non-Nix files is invoked by nothing in-repo; its fate is a TODO_LIST decision).
- `probeTimeoutSeconds < checkIntervalSeconds` is an eval-time assertion — keep it.

## Commands

```bash
nix flake check   # formatting + module-contract checks (eval + trivial builds)
nix fmt           # treefmt wrapper (flake formatter)
```

## Checks

`flake.nix` `module-contract` asserts: unit present when enabled / absent when disabled, quickshell in ExecStart, env contract in unit text, MemoryMax set, sandbox hardening present with `NoNewPrivileges` absent (it would strip ping's cap_net_raw), and the probe-overlap assertion fires on a bad config. Rendering itself is NOT tested here (needs a live compositor) — see TODO_LIST for the VM-test debt and the standalone `quickshell -p` demo recipe.

## Consumers

- SystemNix (evo-x2) — cutover from the in-tree module to this input is queued there (docs/todo/desktop.md); the push landed 2026-10-16, and execution is gated on the hardened-unit live smoke test (TODO_LIST).
