<!-- FEATURES.md — living inventory. Statuses are honest, evidence-cited, and
     never rounded up. Updated as features ship, change, or break. -->

# Features

> Honest inventory of what this project does, by status. Built from the code,
> not the marketing. Audited 2026-10-16 at HEAD `a6950e0`; re-verified 2026-10-17
> against the tagged v0.1.0 tree with new evidence: first green CI runs, the
> probe-transitions machine test, and a live sandbox smoke test on evo-x2
> (which found and fixed the /run/user write blocker).

## Status legend

| Status                    | Meaning                                                                                                                                |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| 🟢 `FULLY_FUNCTIONAL`     | Works as intended, exercised by tests or daily use.                                                                                    |
| 🟡 `PARTIALLY_FUNCTIONAL` | Ships but has known gaps, edge-case bugs, or missing pieces.                                                                           |
| 🔴 `BROKEN`               | Present in code but failing. Keep BROKEN nameable — "zero BROKEN rows" is itself information.                                          |
| 🔵 `DISABLED`             | Code exists and is correct, but execution is externally switched off. A switch, not a fix — never fold into BROKEN.                    |
| ⚪ `PLANNED`              | No code yet; genuinely next on the build path.                                                                                         |

> Detection and unit behavior are now machine-verified (probe-transitions) and
> live-smoke-verified on evo-x2. The remaining PARTIALLY_FUNCTIONAL rows share
> one narrow cause: the 2026-10-17 session had zero active outputs, so pixel
> visibility on a real monitor is unproven — the QML ran on Qt's placeholder
> screen. First real render proof rides the SystemNix switch (or any
> monitor-on session).

## Detection

| Feature                                        | Status                    | Evidence                                | Notes                                                                                          |
| ---------------------------------------------- | ------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Two-leg connectivity probe                     | 🟢 `FULLY_FUNCTIONAL`     | `module.nix` probe Process; `probe-transitions` check | Carrier glob (`/sys/class/net`, virtual ifaces excluded) → "link"; ICMP echo → "net". Live-verified: ping under sandbox → ok; blackhole → net. NOT `nmcli` — see README. |
| Fail-visible probe semantics                   | 🟢 `FULLY_FUNCTIONAL`     | `probe-transitions` check               | A probe that cannot even run counts as failure ("net"), never as success; transition-tested.   |
| Debounced show/hide                            | 🟢 `FULLY_FUNCTIONAL`     | `probe-transitions` check; live smoke   | `failuresToShow` consecutive failures to appear; hides on first clean probe; re-arms for fresh outages. Machine-asserted and live-counted. |
| IPv4-only internet leg (documented tradeoff)   | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix` probeHost option           | v6-up/v4-down shows "offline" while v6 browsing works — accepted tradeoff, documented in the option description + README; point probeHost at a v6 literal on v6-primary hosts. |

## Presentation

| Feature                                        | Status                    | Evidence                                | Notes                                                                                          |
| ---------------------------------------------- | ------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Yellow top-strip on every monitor              | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix` Variants                   | One `PanelWindow` per screen via `Variants`; static `#f2f9e2af`, never flashing. DP-1 proven on the origin host; the 2026-10-17 smoke session had zero active outputs, so pixel visibility awaits a monitor-on session. |
| Push-down animation                            | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix` Behavior on animHeight     | `WlrLayer.Top` + `ExclusionMode.Auto` + animated height (InOutCubic, 450 ms). Logic transition-verified; pixels captured in the README demo (headless sway) — live-monitor proof pending as above. |
| Last-online caption                            | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix` fmtAgo + tick Timer        | "last online 4m 12s ago" re-evaluated every second while visible; `unknown` before the first clean probe. Pixel proof pending as above. |
| Click-to-dismiss with re-arm                   | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix` MouseArea + dismissed      | Re-arm logic transition-verified (recovery → fresh outage shows again). The physical click itself awaits a pointer harness or first real outage. |

## Operations

| Feature                                        | Status                    | Evidence                                | Notes                                                                                          |
| ---------------------------------------------- | ------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| systemd user unit on graphical-session.target  | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix` unit wiring                | Auto-start with the graphical session. The origin host's first start was manual; reboot/re-login unproven (TODO_LIST). |
| systemd sandbox hardening                      | 🟢 `FULLY_FUNCTIONAL`     | live smoke 2026-10-17; `unit-verify`    | Full directive set contract-checked line-by-line, `systemd-analyze verify` clean, and live-proven on evo-x2: unit active, ping cap_net_raw intact, runtime dirs writable via RuntimeDirectory+ReadWritePaths (the smoke FOUND the /run/user blocker — fixed). GPU render path unverified (zero outputs that session). |
| Live tuning via `OFFLINE_BANNER_*` drop-in     | 🟢 `FULLY_FUNCTIONAL`     | live smoke (env-driven runs)            | Env contract mirrors the options; retune without rebuild (unit restart required — env is read at start). Asserted by `module-contract`; exercised live with PROBE_HOST/INTERVAL/FAILURES overrides. |
| State-transition observability                 | 🟢 `FULLY_FUNCTIONAL`     | live smoke journal + state file         | Journal lines on failed probes, show/hide, recovery, dismiss; `$XDG_RUNTIME_DIR/offline-banner/state` rewritten every probe — stale file = dead unit (fail closed). Live-verified. |
| Demo mode (`OFFLINE_BANNER_DEMO=1`)            | 🟢 `FULLY_FUNCTIONAL`     | `module.nix` demo property; live run    | Force-show with probes skipped (Process never starts); live-verified (state shows `demo:true`, active:true). |
| Probe-overlap eval assertion                   | 🟢 `FULLY_FUNCTIONAL`     | `module-contract` check                 | Proven to fire on a bad config and stay silent on a good one. |
| `failuresToShow` sanity bound                  | 🟢 `FULLY_FUNCTIONAL`     | `module.nix` assertions                 | Eval-time bound (≤ 10) with a clear message; negative-tested. |
| Flake checks (4 gates, both systems)           | 🟢 `FULLY_FUNCTIONAL`     | `flake.nix` checks                      | formatting, module-contract (full sandbox + restartTriggers), unit-verify, docs-drift, probe-transitions — green locally on x86_64+aarch64 (qemu binfmt) and in CI. |
| CI (GitHub Actions flake check)                | 🟢 `FULLY_FUNCTIONAL`     | `.github/workflows/checks.yml`          | First green run 2026-10-17 after re-pinning the installer action (single-char SHA typo 422'd every run); read-only token, no persisted credentials; aarch64 via qemu binfmt; branch protection requires it; dependabot keeps the pins current; actionlint + zizmor clean. |
| Release (v0.1.0)                               | 🟢 `FULLY_FUNCTIONAL`     | git tag + GitHub Release                | Tagged on a green pipeline; CHANGELOG body; MIT license; repo topics set; CI badge live. |

## Integration

| Feature                                        | Status                    | Evidence                                | Notes                                                                                          |
| ---------------------------------------------- | ------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| NixOS module `services.offline-banner`         | 🟢 `FULLY_FUNCTIONAL`     | `module.nix` options                    | 7 options: `enable`, `package`, `checkIntervalSeconds`, `probeHost`, `probeTimeoutSeconds`, `failuresToShow`, `layerNamespace` (drift-gated against this file + README); evaluates + checks on x86_64- and aarch64-linux. Consumed by SystemNix (evo-x2). |

## Planned

| Feature                                        | Status       | Evidence                                | Notes                                                                                          |
| ---------------------------------------------- | ------------ | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Live render proof on a real monitor            | ⚪ `PLANNED`  | TODO_LIST (rides SystemNix switch)      | Pixel visibility: banner visible on every active output; closes the PARTIALLY rows above. |
| Click-dismiss physical harness                 | ⚪ `PLANNED`  | TODO_LIST (T18)                         | Virtual-pointer harness or first live outage retires the last unverified interaction. |
| Reboot/re-login auto-start proof               | ⚪ `PLANNED`  | TODO_LIST (T18)                         | graphical-session.target wiring proven at reboot. |
