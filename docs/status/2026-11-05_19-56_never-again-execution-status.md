# Never-Again Execution — hardening stack shipped, queue harvested

**Written:** 2026-11-05 19:56 CET · **Input state:** `97b8056` (green on both workflows, per the 19-25 report) + the prior session's in-flight M09/M10/M15/M16 tree state.
**Mission:** execute the never-again pareto plan's non-owner-gated items end-to-end — the 226/NAMESPACE incident class made structurally impossible, the tooling debts closed, the docs truthful — and leave the owner a one-evening path to v0.2.1 + switch.

## §a What shipped (all verified, all local, nothing pushed)

| Commit        | What                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Verified by                                                                                                                                                  |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `825d43b`     | prior session's status report + TS7 watch row (daemon sweep re-split)                                                                                                                                                                                                                                                                                                                                                                                                                    | n/a (docs)                                                                                                                                                   |
| `2cc6a16`     | **M09+M10+M15+M16+M06+M11**: ReadWritePaths derived from provisioned lists; module-contract provisioning invariant + synthetic-hole teeth; opt-out negative fixture + bad-historyPath teeth; link-cue positive assert; `packages.vm-smoke`; `nix run .#smoke` + `smoke-script` gate                                                                                                                                                                                                      | module-contract, unit-verify, probe-transitions ×2, render-smoke unchanged; rendered unit inspected (3 holes, 2 provisioners, set-identical to pre-refactor) |
| `569a4fe`     | **M20+M21+F71**: waybar `since` (offline 4m / 1h6m), `scripts/play-sounds.sh`, `packages.sounds`, `shell-scripts` gate                                                                                                                                                                                                                                                                                                                                                                   | shellcheck+shfmt clean ×3 files; consumer exercised against 5 fake state files (since set/null/demo/inactive/stale); gate + sounds builds green              |
| `9ace19a`     | **M18+M23-adjacent**: `workflow-lint` job (actionlint + zizmor offline, nix-provided); deploy pinned to nix firebase-tools @ flake.lock rev; `persist-credentials: false` on both workflows' checkouts                                                                                                                                                                                                                                                                                   | zizmor "No findings to report" (was: 2 artipacked + 1 adhoc-packages); actionlint clean; pinned firebase-tools 15.34.0 resolves                              |
| (this commit) | docs batch: FEATURES sound-row + 9-gates annotation; two ANNOTATEs in the 01-51 report (rides-the-switch claims); launch drafts v0.2 refresh; CHANGELOG [Unreleased] extended; website cookbook (jq recipes verified against synthetic data) + v6 example; AGENTS refresh (9 checks, daemon-manifest rule, dprint source, consumers still pre-fix, smoke runbook); TODO_LIST harvest + 6 errata; dprint.json re-drop (source identified: BuildFlow auto-generation in non-managed repos) | website verify below                                                                                                                                         |

## §b Negative proofs (the teeth)

1. **VM smoke, negative-proven** (F38): scratch edit removing the StateDirectory provisioner → `test -d /home/smoke/.local/state/offline-banner` fails AND the journal shows the exact incident line — `Failed at step NAMESPACE spawning …/quickshell: No such file or directory`. Reverted; positive run green again.
2. **Provisioning invariant, negative-proven** (F49): a synthetic `mkForce ["%t/unprovisioned-hole"]` eval flips the computed invariant false; the check asserts both the default-config pass AND the hole detection.
3. **Negative fixtures**: opt-out config asserted inert + assertion-free; `/opt/...` ledger parent fires exactly the provisioning assertion; relative path additionally fails the absolute-path assertion.

## §c Findings worth keeping

- **dprint zombie source identified** (errata 4 → resolved): BuildFlow auto-generates dprint.json in any repo it scans that lacks a `.buildflow.yml` (seen live in the domains repo's preflight output). Re-drops WILL resurrect until D4 or a BuildFlow skip mechanism; AGENTS records this.
- **M17 was already done**: render-smoke carries the doctrine (`wait_pixel` transition polls, settled evidence frames); the TODO row was stale. Audited, no change made (verschlimmbessern avoided).
- **Dependabot self-resolved**: 0 open alerts (was 20) — recorded DONE BY EVENTS.
- The 19-25 report's "unauthored in-flight plan execution" is now a completed, owned execution: M09/M10/M15/M16 shipped in `2cc6a16` with the full verification stack above.

## §d Still open — every item owner-gated (the one-evening path)

1. **Push** (owner): everything sits unpushed on master; both workflows were green on `97b8056`, and every gate was re-run locally after each change — but push only after re-checking `gh run list` (standing rule 1).
2. **v0.2.1 cut** (D2): CHANGELOG [Unreleased] is pre-folded; website changelog.mdx section still wanted before the tag.
3. **SystemNix lock → v0.2.1 + switch** — evo-x2 remains protected only by the manual mkdir (lock = pre-fix `2ccdf6e`).
4. **D1**: promote `packages.vm-smoke` into checks (blocking) or wire advisory.
5. **Live-proof evening** (M04/M05) + **waybar deployment on the bar** (M08) — post-switch.
6. M27 remainder: social-preview upload (manual, no API).

## §e Gates run this session (local, all green)

`nix fmt` after every edit; `module-contract`, `unit-verify`, `probe-transitions` (×2), `render-smoke` (untouched), `shell-scripts`, `smoke-script`, `docs-drift` (via flake check), `vm-smoke` (positive + negative), `sounds` build; shellcheck+shfmt on three scripts; zizmor+actionlint on both workflows; website verify (see below); terraform fmt on the domains file. Full `nix flake check --all-systems` rides the owner's pre-push gate.
