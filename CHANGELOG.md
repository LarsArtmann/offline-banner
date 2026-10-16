# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com); versioning waits for the first tag.

## [Unreleased]

### Added

- `FEATURES.md` — honest, evidence-cited feature inventory (runtime rows honestly PARTIALLY_FUNCTIONAL pending the live smoke test; CI honestly BROKEN on the unresolvable action pin).
- `ROADMAP.md` — long-term themes (probe expressiveness, operational smoothness, verification depth) and explicit non-goals.
- `docs/status/README.md` — index for the status-report snapshots.
- README: consumer `nixpkgs.follows` quickstart line (avoids a duplicated lock entry), hardened-unit bullet, restart note on env-drop-in tuning.
- TODO_LIST rebuilt from the 2026-10-16 nix-skills review harvest (deduped and routed; stale "blocked on push" row retired — the push landed).

### Fixed

- README: compositor-compatibility claim softened to the verified subset (proven on niri; others expected but untested).

## [0.1.0] — 2026-10-16

### Added

- Initial extraction from SystemNix (`modules/nixos/desktop/offline-banner.nix`, deployed there as gen 904) into a standalone flake: `services.offline-banner` NixOS module with v3 behavior — static yellow top-strip on every monitor, carrier-glob + ICMP probe (NOT `nmcli networking connectivity`), 2-failure debounce, top-layer push-down animation (`WlrLayer.Top` + `ExclusionMode.Auto`, InOutCubic 450 ms), last-online caption, click-to-dismiss.
- New options vs the SystemNix original: `package` (Quickshell package override, `mkPackageOption`) and `layerNamespace` (WlrLayershell namespace, default `offline-banner`; SystemNix sets `systemnix:offline-banner` for live parity during cutover).
- Flake checks: treefmt (nixfmt + statix) formatting + a `module-contract` check asserting unit presence/absence, quickshell ExecStart, the `OFFLINE_BANNER_*` env contract, MemoryMax, and the probe-overlap assertion firing on a bad config.
- CI workflow (flake check) — activates once the remote exists.

### Security

- Systemd sandbox for the user unit: `ProtectSystem=strict`, `ProtectHome=read-only`, `PrivateTmp`, `RestrictAddressFamilies` (unix/inet/inet6/netlink), namespaces/personality/realtime/suid-sgid restrictions, and kernel/clock/hostname/proc protections. `NoNewPrivileges` is deliberately not set (it would strip iputils' `cap_net_raw` file capability and break the ICMP probe); GPU/JIT/seccomp options withheld until live-verified. Hardening is contract-checked (`module-contract` asserts the unit text).

### Notes

- The `OFFLINE_BANNER_{INTERVAL,PROBE_HOST,PROBE_TIMEOUT,FAILURES}` env-var contract is unchanged from SystemNix — live drop-in tuning and the unroutable-IP demo hack keep working.
