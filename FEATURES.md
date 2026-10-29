<!-- FEATURES.md — living inventory. Statuses are honest, evidence-cited, and
     never rounded up. Updated as features ship, change, or break. -->

# Features

> Honest inventory of what this project does, by status. Built from the code,
> not the marketing. Audited 2026-10-16 at HEAD `a6950e0`; re-verified 2026-10-17
> against the tagged v0.1.0 tree with new evidence: first green CI runs, the
> probe-transitions machine test, and a live sandbox smoke test on evo-x2
> (which found and fixed the /run/user write blocker). Re-verified again
> 2026-10-17 ~10:45: `render-smoke` pixel gate, frame-watched demo assets,
> structured journal tokens, and the waybar consumer. Rows added 2026-10-28/29
> (sound cues, outage ledger) with same-day machine + real-run evidence.

## Status legend

| Status                    | Meaning                                                                                                                                |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| 🟢 `FULLY_FUNCTIONAL`     | Works as intended, exercised by tests or daily use.                                                                                    |
| 🟡 `PARTIALLY_FUNCTIONAL` | Ships but has known gaps, edge-case bugs, or missing pieces.                                                                           |
| 🔴 `BROKEN`               | Present in code but failing. Keep BROKEN nameable — "zero BROKEN rows" is itself information.                                          |
| 🔵 `DISABLED`             | Code exists and is correct, but execution is externally switched off. A switch, not a fix — never fold into BROKEN.                    |
| ⚪ `PLANNED`              | No code yet; genuinely next on the build path.                                                                                         |

> Detection and unit behavior are now machine-verified (probe-transitions) and
> live-smoke-verified on evo-x2; banner RENDERING is pixel-verified in CI by
> `render-smoke` (headless sway: strip yellow present when shown, absent below
> it and after recovery) and the demo assets were frame-watched (push-down and
> recovery slide-up both visible). The remaining PARTIALLY_FUNCTIONAL rows share
> one narrow cause: no proof yet on a REAL monitor in a live session (the
> 2026-10-17 sessions saw zero active outputs — recon showed the only
> compositor session displayless by circumstance, DP-1 connected but
> DRM-disabled, not a module bug). That proof rides the SystemNix switch (or
> any monitor-on session).

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
| Yellow top-strip on every monitor              | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix` Variants; `render-smoke` check | One `PanelWindow` per screen via `Variants`; static `#f2f9e2af`, never flashing. Pixel-proven in headless sway (render-smoke asserts the composited strip color when shown, absence below it and after recovery); DP-1 proven on the origin host. Real-monitor visibility awaits a monitor-on session. |
| Push-down animation                            | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix` Behavior on animHeight; demo frames | `WlrLayer.Top` + `ExclusionMode.Auto` + animated height (InOutCubic, 450 ms). Transition-verified; pixels proven by render-smoke; the regenerated demo webp was frame-watched — the push-down and the recovery slide-up are visibly animated (frames 095→098→120 entry, 176→179 exit). Real-monitor proof pending as above. |
| Last-online caption                            | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix` fmtAgo + tick Timer        | "last online 4m 12s ago" re-evaluated every second while visible; `unknown` before the first clean probe. Pixel proof pending as above. |
| Click-to-dismiss with re-arm                   | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix` MouseArea + dismissed      | Re-arm logic transition-verified (recovery → fresh outage shows again). The physical click itself awaits a pointer harness or first real outage. |

## Operations

| Feature                                        | Status                    | Evidence                                | Notes                                                                                          |
| ---------------------------------------------- | ------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| systemd user unit on graphical-session.target  | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix` unit wiring                | Auto-start with the graphical session. The origin host's first start was manual; reboot/re-login unproven (TODO_LIST). |
| systemd sandbox hardening                      | 🟢 `FULLY_FUNCTIONAL`     | live smoke 2026-10-17; `unit-verify`    | Full directive set contract-checked line-by-line, `systemd-analyze verify` clean, and live-proven on evo-x2: unit active, ping cap_net_raw intact, runtime dirs writable via RuntimeDirectory+ReadWritePaths (the smoke FOUND the /run/user blocker — fixed). Fontconfig cache routed to a writable runtime dir (`XDG_CACHE_HOME=%t/offline-banner/cache`, contract-asserted). |
| Live tuning via `OFFLINE_BANNER_*` drop-in     | 🟢 `FULLY_FUNCTIONAL`     | live smoke (env-driven runs)            | Env contract mirrors the options; retune without rebuild (unit restart required — env is read at start). Asserted by `module-contract`; exercised live with PROBE_HOST/INTERVAL/FAILURES overrides. |
| State-transition observability                 | 🟢 `FULLY_FUNCTIONAL`     | live smoke journal + state file         | Structured journal tokens on every transition — `probe ok recovered_after=N`, `probe failed reason=… failures=N/M`, `banner state=shown\|hidden\|dismissed reason=… failures=N/M` (user-visible format change, [Unreleased]); `$XDG_RUNTIME_DIR/offline-banner/state` rewritten every probe — stale file = dead unit (fail closed). Live-verified; shipped with a reference waybar consumer. |
| Waybar consumer (reference)                    | 🟢 `FULLY_FUNCTIONAL`     | `contrib/offline-banner-waybar` tests   | POSIX sh + jq; offline widget while active, silent while fine, `stale` marker when the heartbeat exceeds `OFFLINE_BANNER_MAX_AGE` (default 15 s). Five fabricated-state tests pass. Not part of the module, not contract-checked. |
| Demo mode (`OFFLINE_BANNER_DEMO=1`)            | 🟢 `FULLY_FUNCTIONAL`     | `module.nix` demo property; live run    | Force-show with probes skipped (Process never starts); live-verified (state shows `demo:true`, active:true). |
| Sound cues (3 synthesized themes)             | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix` playSound + offlineBannerSounds; `probe-transitions` | chime/droplet/retro, build-time-synthesized (stdlib-only Python in-module, 3×4 theme/event matrix, WAV-matrix-gated by `shell-content`). One cue per outage (lower pitch for link), one on recovery, a tick on dismiss; `soundTheme="none"` opts out. Machine-verified: which cue fires at which transition (OFFLINE_BANNER_SOUND_CMD seam); REAL playback verified 2026-10-28 (real store QML + pw-play through the host PipeWire, headless sway). NOT yet live-proven: playback from inside the hardened unit (rides the SystemNix switch). |
| Persistent outage ledger (`historyPath`)       | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix` rememberOutage; `probe-transitions` | One JSONL entry per COMPLETED outage (from/to/durationSec/reasons/probeFailures) appended to `~/.local/state/offline-banner/history.jsonl`; sub-debounce blips and open outages never enter, demo never writes; `state.since` mirrors the live outage. Machine-verified via the check harness (entry contents asserted with jq; open-outage and demo negatives asserted) AND a real-file append verified 2026-10-28 (real QML run, entry `{"from":…,"to":…,"durationSec":2,…}`). NOT yet live-proven: the %h ReadWritePaths home-write hole under the real sandbox (same live-proof ride). |
| Probe-overlap eval assertion                   | 🟢 `FULLY_FUNCTIONAL`     | `module-contract` check                 | Proven to fire on a bad config and stay silent on a good one. |
| `failuresToShow` sanity bound                  | 🟢 `FULLY_FUNCTIONAL`     | `module.nix` assertions                 | Eval-time bound (≤ 10) with a clear message; negative-tested. |
| Flake checks (7 gates, both systems)           | 🟢 `FULLY_FUNCTIONAL`     | `flake.nix` checks                      | formatting, module-contract (full sandbox + restartTriggers + cacheDirSet), unit-verify, shell-content, docs-drift, probe-transitions (journal asserts + empty-probe + demo + heartbeat), render-smoke (pixel gate) — green locally on x86_64+aarch64 (qemu binfmt) and in CI. |
| CI (GitHub Actions flake check)                | 🟢 `FULLY_FUNCTIONAL`     | `.github/workflows/checks.yml`          | First green run 2026-10-17 after re-pinning the installer action (single-char SHA typo 422'd every run); read-only token, no persisted credentials; aarch64 via qemu binfmt; branch protection requires it; dependabot keeps the pins current; actionlint + zizmor clean. |
| Release (v0.1.0)                               | 🟢 `FULLY_FUNCTIONAL`     | git tag + GitHub Release                | Tagged on a green pipeline; CHANGELOG body; MIT license; repo topics set; CI badge live. |

## Integration

| Feature                                        | Status                    | Evidence                                | Notes                                                                                          |
| ---------------------------------------------- | ------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| NixOS module `services.offline-banner`         | 🟢 `FULLY_FUNCTIONAL`     | `module.nix` options                    | 11 options: `enable`, `package`, `checkIntervalSeconds`, `probeHost`, `probeTimeoutSeconds`, `failuresToShow`, `layerNamespace`, `soundTheme`, `soundVolume`, `enableHistory`, `historyPath` (drift-gated against this file + README); evaluates + checks on x86_64- and aarch64-linux. Consumed by SystemNix (evo-x2). |

## Planned

| Feature                                        | Status       | Evidence                                | Notes                                                                                          |
| ---------------------------------------------- | ------------ | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Live render proof on a real monitor            | ⚪ `PLANNED`  | TODO_LIST (rides SystemNix switch)      | Headless pixels are CI-proven (render-smoke) and the demo is frame-watched; this row is now only real-monitor, live-session visibility — banner visible on every active output; closes the PARTIALLY rows above. |
| Click-dismiss physical harness                 | ⚪ `PLANNED`  | TODO_LIST (T18)                         | Virtual-pointer harness or first live outage retires the last unverified interaction. |
| Reboot/re-login auto-start proof               | ⚪ `PLANNED`  | TODO_LIST (T18)                         | graphical-session.target wiring proven at reboot. |
