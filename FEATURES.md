<!-- FEATURES.md — living inventory. Statuses are honest, evidence-cited, and
     never rounded up. Updated as features ship, change, or break. -->

# Features

> Honest inventory of what this project does, by status. Built from the code,
> not the marketing. Audited 2026-10-16 against `module.nix`, `flake.nix`, and
> `.github/workflows/checks.yml` at HEAD `a6950e0`; the CI-pin failure was
> verified live against the GitHub API that day.

## Status legend

| Status                    | Meaning                                                                                                                                |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| 🟢 `FULLY_FUNCTIONAL`     | Works as intended, exercised by tests or daily use.                                                                                    |
| 🟡 `PARTIALLY_FUNCTIONAL` | Ships but has known gaps, edge-case bugs, or missing pieces.                                                                           |
| 🔴 `BROKEN`               | Present in code but failing. Keep BROKEN nameable — "zero BROKEN rows" is itself information.                                          |
| 🔵 `DISABLED`             | Code exists and is correct, but execution is externally switched off. A switch, not a fix — never fold into BROKEN.                    |
| ⚪ `PLANNED`              | No code yet; genuinely next on the build path.                                                                                         |

> The runtime banner features below are `PARTIALLY_FUNCTIONAL` across the board
> for one reason, not many: the behavior is live-proven from its SystemNix
> origin (deployed there as gen 904, v3), but nothing has been runtime-verified
> since extraction — and the systemd sandbox added afterwards is eval-checked
> only. The pending live smoke test (TODO_LIST) is the single gate that flips
> this whole block.

## Detection

| Feature                                        | Status                    | Evidence                                | Notes                                                                                          |
| ---------------------------------------------- | ------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Two-leg connectivity probe                     | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix:152-162`                    | Carrier glob (`/sys/class/net`, virtual ifaces excluded) → "link"; ICMP echo → "net". NOT `nmcli` — see README. |
| Fail-visible probe semantics                   | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix:133-147`                    | A probe that cannot even run counts as failure ("net"), never as success.                      |
| Debounced show/hide                            | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix:105-107`, `module.nix:133-147` | `failuresToShow` consecutive failures to appear (default 2 ≈ 10 s); hides on the first clean probe. |
| IPv4-only internet leg                         | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix:162`                        | Known blind spot: v6-up/v4-down shows "offline" while browsing works. Fix or documented tradeoff is planned. |

## Presentation

| Feature                                        | Status                    | Evidence                                | Notes                                                                                          |
| ---------------------------------------------- | ------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Yellow top-strip on every monitor              | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix:198-206`                    | One `PanelWindow` per screen via `Variants`; static `#f2f9e2af`, never flashing. Only DP-1 proven on the origin host. |
| Push-down animation                            | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix:207-235`                    | `WlrLayer.Top` + `ExclusionMode.Auto` + animated height (InOutCubic, 450 ms): the bar is pushed down, nothing covered. |
| Last-online caption                            | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix:111-131`, `module.nix:189-196` | "last online 4m 12s ago" re-evaluated every second while visible; `unknown` before the first clean probe. |
| Click-to-dismiss with re-arm                   | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix:115-118`, `module.nix:242-247` | Dismisses for the rest of THIS outage; the next clean probe re-arms it. Never machine-verified. |

## Operations

| Feature                                        | Status                    | Evidence                                | Notes                                                                                          |
| ---------------------------------------------- | ------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| systemd user unit on graphical-session.target  | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix:285-289`                    | Auto-start with the graphical session. The origin host's first start was manual; reboot/re-login unproven. |
| systemd sandbox hardening                      | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix:310-346`                    | `ProtectSystem=strict`, restricted address families, kernel/clock/hostname protections. Eval-checked only; live smoke pending. `NoNewPrivileges` deliberately absent (it strips ping's `cap_net_raw`). |
| Live tuning via `OFFLINE_BANNER_*` drop-in     | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix:291-306`                    | Env contract mirrors the options; retune without rebuild (unit restart required — env is read at start). Contract asserted by `module-contract`. |
| Probe-overlap eval assertion                   | 🟢 `FULLY_FUNCTIONAL`     | `module.nix:278-283`, `flake.nix:88-99` | `module-contract` proves it fires on a bad config and stays silent on a good one; green locally. |
| Flake checks (formatting + module-contract)    | 🟢 `FULLY_FUNCTIONAL`     | `flake.nix:101-143`                     | `nix flake check` green on x86_64-linux (run twice, 2026-10-16). aarch64 leg unexercised locally. |
| CI (GitHub Actions flake check)                | 🔴 `BROKEN`               | `.github/workflows/checks.yml:16`       | `nix-installer-action` pin does not resolve (GitHub API 422, verified 2026-10-16); both master runs red in ~6 s. No nix check has ever executed in CI. Fix tracked in TODO_LIST. |

## Integration

| Feature                                        | Status                    | Evidence                                | Notes                                                                                          |
| ---------------------------------------------- | ------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| NixOS module `services.offline-banner`         | 🟡 `PARTIALLY_FUNCTIONAL` | `module.nix:43-77`                      | 7 options (`enable`, `package`, `checkIntervalSeconds`, `probeHost`, `probeTimeoutSeconds`, `failuresToShow`, `layerNamespace`); evaluates on x86_64- and aarch64-linux. Runtime debt as above. |

## Planned

| Feature                                        | Status       | Evidence                                | Notes                                                                                          |
| ---------------------------------------------- | ------------ | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| VM/negative test harness                       | ⚪ `PLANNED`  | No code; TODO_LIST Quality              | `OFFLINE_BANNER_SYSROOT` + probe injection; link/net/ok/debounce transition assertions. Completes the verification family. |
| State-transition observability                 | ⚪ `PLANNED`  | No code; TODO_LIST Quality              | Journal line on show/hide + fail-closed `offline_banner_active` gauge — a dead banner is currently silent. |
| Demo mode (`OFFLINE_BANNER_DEMO=1`)            | ⚪ `PLANNED`  | No code; TODO_LIST Quality              | Force-show without probes; retires the unroutable-IP drop-in hack. |
| IPv6 probe leg or documented v4-only tradeoff  | ⚪ `PLANNED`  | No code; TODO_LIST Quality              | Closes the Detection blind spot above. |
