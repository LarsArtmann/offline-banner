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
- `render-smoke` flake check — the pixel gate: drives the real probe path (control file, not demo mode) in headless sway, grim-captures hidden → shown → recovered, and asserts the strip's composited yellow (`#f2f9e2af` at 95% alpha) at the strip when shown, its absence below the strip and after recovery. Banner rendering is now proven in CI without a monitor (4cff63a).
- Reference waybar consumer `contrib/offline-banner-waybar` (POSIX sh + jq, five fabricated-state tests): emits an offline widget while the banner is active, stays empty while fine, and flips to a `stale` marker once the state file's heartbeat exceeds `OFFLINE_BANNER_MAX_AGE` (default 15 s). Not part of the module, not contract-checked (767728b).
- AGENTS.md Runbooks: the live-smoke `systemd-run` recipe (with the literal-paths caveat — `%t` does not expand in bus-transient properties) and a five-step release runbook.

### Changed

- **Journal lines are now structured tokens** — `probe ok recovered_after=N`, `probe failed reason=net failures=N/M`, `banner state=shown|hidden reason=… failures=N/M`, `banner state=dismissed rearm=next_clean_probe` — replacing the prose sentences. Anything grepping the old wording must switch; `journalctl --user -u offline-banner -f | grep "banner state="` is the supported surface.
- `probe-transitions` extended into a full transition ledger: asserts the journal lines themselves (not only the state file), the fail-visible empty-probe-output case, demo mode (`OFFLINE_BANNER_DEMO=1` second instance), and the state file's freshness heartbeat — plus counter/heartbeat deflakes for slow emulated runners (cade264, 39d51bf, 8a14308).
- Demo assets (`docs/assets/offline-banner-demo.{webp,png}`) regenerated from the CURRENT ground-truth QML, and the frame content verified by eye: push-down on link loss and the recovery slide-up are both visible (the 03:04 PNG had silently been captured from a stale cached 00:06 QML).

### Fixed

- Sandbox: fontconfig could not write its cache under `ProtectSystem=strict`+read-only HOME — the unit now sets `XDG_CACHE_HOME=%t/offline-banner/cache` (runtime dir), contract-asserted by `module-contract` (`cacheDirSet`).
- `scripts/capture-demo.sh` hung forever after recording: `wf-recorder` finalizes on SIGINT by draining its compositor connection, which never completes once sway is dead — the script now polls and escalates to SIGKILL (a 7-hour hang on 2026-10-17). The ground-truth QML is re-extracted every run (a cached copy is what produced the stale 03:04 PNG), and the script is shellcheck/shfmt clean.
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

---

[Unreleased]: https://github.com/LarsArtmann/offline-banner/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/LarsArtmann/offline-banner/compare/fff0b61...v0.1.0
