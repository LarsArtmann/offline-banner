# Changelog

All notable changes to this project are documented here. Format follows [Keep a Changelog](https://keepachangelog.com).

## [Unreleased]

### Added

- Project website (Astro + Starlight + Tailwind v4): landing page with the 24 s demo as the hero centerpiece, options/observability/limitations docs, and the module's own visual identity (banner yellow on the demo's dark palette). Live at https://offline-banner.lars.software (custom domain: DNS applied by the owner, cert ACTIVE, landing + demo.mp4 verified over HTTPS) and https://offline-banner.web.app.
- 24 s promo video rendered from a committed HyperFrames composition (`website/video/`) using the module's real colors and 450 ms InOutCubic push-down; embedded on the landing page with poster + VideoObject metadata and verified live (HTTP 200, `video/mp4`, immutable cache).
- Website CI workflow (`website.yml`): build + validate (astro check, html-validate) then deploy to Firebase Hosting on master; first real run green; deploy step waits for the `FIREBASE_SERVICE_ACCOUNT` secret and is verified to skip gracefully without it.
- GitHub social-preview card (`assets/branding/social-preview.png`) and repo homepage link.
- README overhauled as the project's sales page: tagline, documentation link bar, "Who is this for?", comparison table, "How it works", and an honest "When NOT to use this" section — all claims traceable to FEATURES/module behavior.
- Launch-post drafts for NixOS Discourse and r/NixOS (`docs/marketing/launch-post-drafts.md`).

### Fixed

- Website CI never started: GitHub Actions rejects the `secrets` context in `if` conditionals, so the first real run failed at parse time (0 s). Deploy steps now gate on a job-level env flag derived from the secret; run green.
- `probe-transitions` check flaked on slow emulated runners: mid-sequence failure-counter asserts now match the transition (reason + counter advanced) instead of an exact count that extra probes could consume between asserts.

## [0.1.0] — 2026-10-17

### Added

- Initial extraction from SystemNix (`modules/nixos/desktop/offline-banner.nix`, deployed there as gen 904) into a standalone flake: `services.offline-banner` NixOS module with v3 behavior — static yellow top-strip on every monitor, carrier-glob + ICMP probe (NOT `nmcli networking connectivity`), 2-failure debounce, top-layer push-down animation (`WlrLayer.Top` + `ExclusionMode.Auto`, InOutCubic 450 ms), last-online caption, click-to-dismiss.
- New options vs the SystemNix original: `package` (Quickshell package override, `mkPackageOption`) and `layerNamespace` (WlrLayershell namespace, default `offline-banner`; SystemNix sets `systemnix:offline-banner` for live parity during cutover).
- Flake checks: treefmt (nixfmt + statix) formatting + a `module-contract` check asserting unit presence/absence, quickshell ExecStart, the `OFFLINE_BANNER_*` env contract, MemoryMax, and the probe-overlap assertion firing on a bad config.
- CI workflow (flake check) — green on both systems (aarch64 via qemu binfmt + extra-platforms).
- MIT license (fleet published-library convention).
- Probe-transition machine test: drives the real store QML through ok/net/link via a probe-command override in headless sway; asserts debounce, reason semantics, recovery, re-arm through the state file.
- Unit-syntax gate: systemd-analyze verify on the rendered unit inside the build sandbox (/run redirected via an LD_PRELOAD shim).
- Docs drift gate: the declared option list is derived from the module eval and must appear in README and FEATURES.
- State-transition observability: journal lines on failed probes, show/hide, recovery, dismiss; JSON state file rewritten on every probe (fail-closed freshness heartbeat).
- Demo mode: `OFFLINE_BANNER_DEMO=1` force-shows with probes skipped.
- `OFFLINE_BANNER_SYSROOT` (internal, test-only) for live probe injection.
- Project docs: `FEATURES.md` (evidence-cited inventory), `ROADMAP.md` (themes + non-goals), status-report index under `docs/status/`, pareto execution plan under `docs/planning/`.

### Fixed

- CI: the `nix-installer-action` pin had a single-character SHA typo — every run died in ~6 s and no nix check had ever executed; re-pinned to the verified v23 commit, token narrowed to `contents: read`, checkout persists no credentials.
- Sandbox: `ProtectSystem=strict` made `/run/user` read-only, breaking quickshell's runtime dirs and the state file (found by the live smoke test, not by eval checks); fixed with `RuntimeDirectory` (offline-banner + quickshell, 0700) and scoped `ReadWritePaths`.
- README: compositor-compatibility claim softened to the verified subset (proven on niri; others expected but untested).
- nixpkgs input moved to `nixos-unstable` (fleet convention; quickshell version identical).

### Security

- Systemd sandbox for the user unit: `ProtectSystem=strict`, `ProtectHome=read-only`, `PrivateTmp`, `RestrictAddressFamilies` (unix/inet/inet6/netlink), namespaces/personality/realtime/suid-sgid restrictions, kernel/clock/hostname/proc protections, and `RuntimeDirectory`+`ReadWritePaths` scoped to exactly the two runtime dirs the unit writes. `NoNewPrivileges` is deliberately not set (it would strip iputils' `cap_net_raw` file capability and break the ICMP probe); GPU/JIT/seccomp options withheld until live-verified. Hardening is contract-checked line-by-line, and the rendered unit passes `systemd-analyze verify` in CI.

### Notes

- The `OFFLINE_BANNER_{INTERVAL,PROBE_HOST,PROBE_TIMEOUT,FAILURES}` env-var contract is unchanged from SystemNix — live drop-in tuning and the unroutable-IP demo hack keep working.
