# Check-Extension + Render-Proof Status Report

**Generated:** 2026-10-17 09:36 CEST · **Session:** single execution push over the 01:59 report's §f "Now" items ("READ, UNDERSTAND, RESEARCH, REFLECT … Execute and Verify one step at a time") · **Work window:** ~02:5x–03:15 CEST · **HEAD at writing:** `a6ed733` (working tree clean — every change below landed via the auto-commit daemon while I was away; several LATER commits by other sessions touched this repo too, see "Return-state observations") · **Repo:** github:LarsArtmann/offline-banner

**Headline:** the banner is now **pixel-proven in CI** — a new `render-smoke` check grim-captures the real store QML in headless sway through hidden → shown → recovered via the real probe path and asserts the strip color. The structured journal contract, the fail-closed state-file consumer, the sandbox cache fix, and the full journal/heartbeat/empty/demo assert set all shipped green. The live-monitor render proof is still correctly gated: the live niri session has a live compositor process but **zero active outputs** (checked ~03:00, same as the 01:48 smoke).

---

## a) FULLY DONE (verified, not claimed)

| #  | Item                                                                                                                                                                                                                          | Evidence |
|----|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|
| 1  | **Baseline green** — `nix flake check` (all 5 then-existing checks) before touching anything                                                                                                                                  | shell output, "all checks passed" |
| 2  | **Structured journal lines (§f-14)** — every transition now emits grep-able tokens: `probe failed reason=net failures=1/2`, `probe ok recovered_after=N`, `banner state=shown\|hidden\|dismissed reason=… failures=N/M`, `banner state=dismissed rearm=next_clean_probe`. Hide-time semantics documented (binding fires on the failures reset, so `reason` still names the outage being recovered from) | module.nix QML; README Observability |
| 3  | **XDG_CACHE_HOME sandbox fix (§f-13)** — unit sets `XDG_CACHE_HOME=%t/offline-banner/cache`; the `%t`-expands-in-`Environment=` question was settled at SOURCE level (systemd `config_parse_environ` runs each word through the unit specifier table — `unit_full_printf`), after the man page proved ambiguous; module-contract gained a `cacheDirSet` assert | module.nix environment; flake.nix module-contract; unit-verify green |
| 4  | **probe-transitions extended (§f-5)** — asserts the structured journal lines (POLLING, see §d-1), the state-file freshness heartbeat (`updatedAt` strictly advances between probes), the empty-probe-output case (fail-visible → `net`, failure 4/2), a no-failure-yet negative journal assert, and a full demo-mode second instance (`{"active":true,"demo":true}` + `state=shown` line) with the stale-write race guarded (`kill` + `wait` + `rm` before relaunch). Check PASSES | `nix build .#checks.x86_64-linux.probe-transitions` → success |
| 5  | **render-smoke: the pixel gate (§f-17)** — NEW check: same headless-sway harness, but drives the REAL probe path (control file, not demo), grim-captures HEADLESS-1 at hidden/shown/recovered, and asserts the `#f2f9e2af` strip (95% alpha → accepted R/G/B ranges: black bg ≈ 236,214,166, white ≈ 249,227,179) present at a strip pixel, absent below the strip and after recovery. PASSES → **rendering is CI-proven**; the "rendering itself is NOT tested" doctrine is rewritten in AGENTS.md | `nix build .#checks.x86_64-linux.render-smoke` → success; AGENTS.md Checks |
| 6  | **State-file consumer v0 (§f-9)** — `contrib/offline-banner-waybar` (POSIX sh + jq): offline widget while active, silent while fine, `stale` marker when the heartbeat exceeds `OFFLINE_BANNER_MAX_AGE` (default 15 s ≈ 3 default intervals). All 5 fabricated-state cases verified; README Observability + AGENTS document it; the "half a ghost system" from §b-3 of the 01:59 report is retired | shell test run, all cases pass |
| 7  | **shellcheck + shfmt clean (§f-10)** — capture-demo.sh: SC2012 fixed at root (`find -printf '%f'` instead of `ls` for socket snapshots), SC2016 fixed structurally (`"$work"` now passed as `$1` to `sh -c 'script' name arg1` — no quote gymnastics); remaining SC2016-through-`unshare` proven a shellcheck exec-following limitation with an isolated repro → single targeted `# shellcheck disable=SC2016` with rationale, recorded in AGENTS. contrib script shfmt-formatted. Both files: SHELLCHECK-CLEAN, SHFMT-CLEAN | nix-shell runs |
| 8  | **README docs** — 500 ms interval floor documented in the options table (§f-11: env values ≤ 500 fall back to the 5000 ms default); startup-race behavior documented (§f-12: zero-output start → Qt placeholder screen, probe keeps running, surfaces appear per connected monitor); journal bullet rewritten for the token format; consumer pointer added; hardened-unit bullet notes the runtime-dir cache | README.md |
| 9  | **AGENTS.md** — seven checks enumerated (incl. render-smoke + the extended probe-transitions), live-evidence paragraph corrected (real-monitor pixels still ride the switch; headless pixels CI-proven), the unshare-SC2016 known-false-positive recorded ("do not refactor it away"), **smoke-test runbook** (§f-6: exact `systemd-run` recipe with the literal-paths caveat + checklist) and **release runbook** (§f-15) added | AGENTS.md Runbooks |
| 10 | **Live recon (time-boxed)** — live niri session found (PID 5049, `wayland-1` socket) but `niri msg outputs` returned empty → live render proof stays gated on a monitor-on session; `wlrctl`/`ydotool` absent from the host → click-dismiss harness remains externally blocked, now with the named missing resource (§e-6 closure bar met); `systemctl`/`systemd-run` blocked by this shell's security policy → the drop-in retune test (§f-4) is not executable from an agent session, recipe documented instead; stale scratch identified: `/run/user/1000/offline-banner.state` (01:44 demo-run artifact written by an intermediate QML revision at a top-level path no current code uses) | shell outputs |
| 11 | **README interval-floor + startup-race + consumer docs verified against the gates** — docs-drift still green after all edits | `nix build .#checks.x86_64-linux.docs-drift` → success |

## b) PARTIALLY DONE

1. **Demo asset regeneration (§f-48)** — the re-run regenerated `docs/assets/offline-banner-demo.png` (03:04, 24 KB) but the webp encode never completed; worse, the run REUSED the script's cached ground-truth QML from 00:06 (`$work/shell.qml` cache in `capture-demo.sh`), so even the fresh PNG has stale provenance. Visually irrelevant (journal lines are non-visual) but the §f-48 provenance point wants a cache-clean re-run. The background job record still shows "running" at 09:36 — almost certainly a hung/stale job, to be killed before any retry.
2. **Demo webp watch (§f-1)** — frames not extracted/viewed: I deliberately waited for the regeneration to avoid watching a stale-provenance asset, and the regeneration itself stalled (§b-1). Still open, still cheap (ffmpeg frame-dump + view).
3. **Scratch cleanup (§f-49)** — the leftover list grew but nothing was trashed yet: `/run/user/1000/offline-banner.state` (new find, same family), `/tmp/qsprobe`, `/tmp/uvroot`, plus `/tmp/offline-banner-demo/` from the stalled capture.
4. **CHANGELOG `[Unreleased]`** — content settled in this session (journal token format, cache fix, render-smoke, consumer, seven checks) but not written to CHANGELOG.md; deferred to the docs-health pass together with the keep-a-changelog compare-link footer (§f-16).

## c) NOT STARTED

1. **docs-health pass** — TODO_LIST/FEATURES updates for this session's outcomes; the 01:59 report's own footer asks for ANNOTATE when brought current; this report also needs indexing in `docs/status/README.md`.
2. **Global lessons write-up (§f-50)** — the quartet (nix-sandbox /run, bus-prop specifier non-expansion, jq `// empty` swallowing false, negative-tests-mutate-semantics) plus two new candidates from this session (poll-or-perish for async harness asserts; lint false positives need an isolated repro before suppression) → crush-config `references/lessons.md` via commit.
3. **SystemNix cross-repo annotation (§f-7)** — `docs/todo/desktop.md` smoke-gate-done note; untouched.
4. **Dependabot PR triage (§f-8)** — `gh pr list` never run.
5. **Treefmt shfmt wiring** — consciously decided AGAINST for now (2 shell files, standalone linters clean; formatter gates CI and is nix-only by recorded decision) — revisit only if shell code grows; recorded here, not in AGENTS (reversible).
6. **Real-monitor render proof, reboot auto-start, multi-monitor, click-dismiss** — unchanged, externally gated (see §a-10); recon confirmed zero outputs again at ~03:00.

## d) TOTALLY FUCKED UP (process failures — nothing shipped broken)

1. **The journal-assert race.** First `probe-transitions` run FAILED: my one-shot `grep` ran before the triggering probe had executed, because `assert_state false` returns instantly on the pre-existing false state. Root cause: I bolted synchronous asserts onto an asynchronous harness without rethinking synchronization. Fixed by making `assert_journal` poll (40 × 0.25 s). One wasted build cycle; the failure itself proves the new asserts have teeth.
2. **AGENTS.md multiedit half-failures, twice.** A 2-edit batch where the second old_string depended on text the first edit had already rewritten, then a repair pass that also mis-tracked what had landed ("Applied 1 of 2", twice). Same failure mode the 01:59 report already flagged (§d-4): reconstructing old_strings from memory instead of re-reading after each landing.
3. **Formatter-daemon race handled, but clumsily.** flake.nix was reformatted between my read and my edit; the mod-time guard caught it, but I then still attempted the edit from the stale read and needed a section re-read. The correct loop is: read → edit → fmt → re-read → edit, always, no exceptions.
4. **Misleading verification output.** In the consumer test the last case's echo label said "expect empty" while the correct behavior printed the offline widget (60 s-old state vs a 120 s threshold override → not stale). The label was wrong, the code was right — but a verification script whose narration lies is its own bug.
5. **Live-session archaeology before liveness.** I spent two calls decoding the /run/user/1000 socket zoo (five stale niri sockets, danklinux leftovers) before checking PID liveness — which answered everything in one step. Liveness-first next time.

## e) WHAT WE SHOULD IMPROVE

1. **Poll-or-perish for async harness asserts** — every assertion against quickshell/sway timers must be a poll with timeout; one-shot greps are only valid after a synchronizing event. Now the pattern in both probe-transitions and render-smoke (`wait_active`).
2. **Source-level verification beat the man page** — for `%t` in `Environment=` the docs were ambiguous ("many settings resolve specifiers"); reading `config_parse_environ` settled it in one search. Keep doing this for systemd semantics (verify-external-claims discipline working as intended).
3. **Root-cause lint fixes over suppressions** — SC2012 → `find`, SC2016 → `$1`-passing; only the proven tool limitation earned a suppression, with an isolated repro and a durable AGENTS note. This is the template for future lint findings.
4. **Closure policy held** — every "blocked" claim in §c-6 now names its missing resource (no active outputs / no wlrctl / systemctl policy-blocked), satisfying the 01:59 §e-6 bar that T18's click item originally failed.
5. **Provenance-sensitive regenerations need fresh caches** — `capture-demo.sh`'s QML cache is a footgun for §f-48-style re-runs; a `--fresh` flag (or trash-the-workdir-by-default) would have saved this run.
6. **Kill stale background jobs before walking away** — the demo-capture job record says "running" six hours later; a hang that outlives the session should be detected (job timeout) rather than rediscovered.

## f) 50 things to get done next

**Now (small, from this session's leftovers):**
1. ~~Kill the hung demo-capture background job; trash `/tmp/offline-banner-demo/` for a clean slate.~~ done — killed 2026-10-17 (wf-recorder 7h SIGINT hang) + /tmp/offline-banner-demo/ trashed
2. ~~Cache-clean re-run of `scripts/capture-demo.sh` (fresh ground-truth QML → honest §f-48 provenance); consider a `--fresh` flag in the script.~~ done — better 2026-10-17 — stale-QML cache guard removed (ground truth re-extracted every run); no --fresh flag needed
3. ~~Watch the regenerated webp end-to-end (§f-1): ffmpeg frame-dump → confirm push-down AND recovery slide-up visible; close §b-4 of the 01:59 report properly.~~ done — frame-watched 2026-10-17 — 179 frames, push-down + slide-up visible; 01:59 §b-4 closed
4. ~~Trash the scratch: `/run/user/1000/offline-banner.state`, `/tmp/qsprobe`, `/tmp/uvroot`.~~ done — trashed 2026-10-17 (all three paths; live unit dir untouched)
5. ~~Write the CHANGELOG `[Unreleased]` section (journal token format = user-visible change; cache fix; render-smoke; consumer; seven checks) + keep-a-changelog compare-link footer (§f-16).~~ done — written 2026-10-17 — [Unreleased] Added/Changed/Fixed + compare-link footer
6. ~~docs-health pass: TODO_LIST row updates (render proof leg of T18 is now CI-covered; live-monitor leg remains), FEATURES updates (new checks, consumer, journal contract), index this report in `docs/status/README.md`, ANNOTATE the 01:59 report per its footer.~~ done — 2026-10-17 — TODO_LIST/FEATURES/status-index updated; 01:59 ANNOTATE applied in this same pass
7. ~~Global lessons quartet + this session's two new lessons → crush-config `references/lessons.md` (by commit there).~~ done at `4f6dd31`
8. ~~SystemNix `docs/todo/desktop.md` annotation (§f-7): smoke gate DONE, switch unblocked — cross-repo handoff.~~ done — annotated 2026-10-17 — v3 row: smoke gate DONE + relock pointer a91a77a
9. ~~Dependabot PR triage (§f-8): `gh pr list`, review + merge if green (protection requires Checks).~~ done — 2026-10-17 — 0 open PRs, 20 alerts (non-gating); nothing to merge
10. ~~Decide treefmt-shfmt wiring for real (I recorded a tentative no — confirm or overturn).~~ **Won't implement — shfmt stays on-demand lint — nix fmt (nixfmt+statix) is the sole style arbiter per AGENTS; capture-demo.sh is shellcheck+shfmt clean.**

**Next (small-medium):**
11. Live render proof the moment outputs exist (§f-3): layer check + grim screenshot on the real monitor; 3-command recipe already in AGENTS.
12. Click-dismiss recon with the named missing tool installed (wlrctl) — half of T18 retireable tonight (§f-2).
13. Drop-in retune test (§f-4): `systemctl --user edit` flow — owner-executable, runbook written; an agent session can't (policy).
14. Reboot/re-login auto-start proof (T18 residual) — schedule with the owner.
15. Multi-monitor proof (headless sway can fake a second output — fold into render-smoke or keep live).
16. Render-smoke hardening: assert a SECOND pixel row (strip edge y≈50) to pin the animated height, and a pixel-diff between hidden.png and shown.png (≥ N changed rows).
17. Extend render-smoke to drive link-reason via sysroot injection and assert the caption text region differs (`reason=link` vs `net` visual states).
18. Structured journal: add `interval=` + `probe_host=` to a startup line for config forensics in the journal.
19. Consumer polish: `-i`/`--once` modes, `--max-age` flag parity with the env var, and a README waybar config snippet.
20. CI: split checks into named jobs for per-gate badges (§f-21 of the 01:59 report, unchanged).
21. Nix output cache to cut the ~60 s CI runs (unchanged).
22. Wire actionlint+zizmor into CI if the workflow grows (unchanged; note: another session's "website CI" commit suggests the workflow grew — triage first).
23. `webp` fallback `<picture>`/poster for markdown clients (unchanged).
24. README architecture diagram (mermaid) (unchanged).
25. Screenshot artifact upload on render-smoke failure (gha artifact) so pixel failures are debuggable from CI.

**Return-state triage (other sessions' work noticed at 09:36, not researched):**
26. ~~`website/` now exists in-repo (another session; "website CI never started — secrets not allowed in step ifs" commit) — reconcile with the docs (AGENTS/Inventory don't mention it yet).~~ done at `ec840bc`
27. ~~`dprint.json` is BACK at the repo root — this contradicts the recorded 2026-10-17 decision ("dropped as uninvoked split brain") still written in AGENTS Hard rules; either the decision was overturned (update AGENTS + TODO row) or the file is a stray (trash it).~~ done — daemon zombie re-add (byte-identical md5, zero invokers) — trashed 2026-10-17; recorded decision stands
28. ~~`assets/` top-level dir appeared — purpose unknown to this session; inventory it.~~ done — GitHub social preview (assets/branding/social-preview.png+svg) — inventoried 2026-10-17
29. ~~`result` symlink at repo root (untracked? git status is clean, so either ignored or committed) — vulnix warned about stale `./result` in the 01:59 era; confirm policy.~~ done — result is gitignored — policy confirmed 2026-10-17
30. ~~The `assets/` + `website/` additions likely need `.gitignore` review (HyperFrames tool state commit suggests churn) — confirm intent.~~ done — .gitignore has a Website section (tool state untracked) — confirmed 2026-10-17

**Unchanged standing items (01:59 report, still valid):**
31. Release runbook exists (AGENTS) — next release (v0.1.1?) is mechanical; see §g-3.
32. Probe-transitions: assert the `qs.log` absence of Qt/fatal errors (currently only greps positive lines).
33. `OFFLINE_BANNER_SYSROOT` live-injection demo documented for the pending VM-test debt (unchanged).
34. nixosTests-style VM test for the systemd wiring (ROADMAP fuel).
35. `packages.<sys>.offline-banner-shell` public passthru (ROADMAP fuel).
36. Example module (`nixosModules.example`) (ROADMAP fuel).
37. Per-monitor namespace suffix (ROADMAP fuel).
38. Metrics endpoint — only on demand (ROADMAP fuel).
39. Second-compositor live proof (ROADMAP fuel).
40. IPv6 probe leg revisit — trigger: a real v6-primary host (ROADMAP fuel).
41. DNS-leg probe — standing non-goal (revisit only with demand).
42. Multi-host probeHost — standing non-goal.
43. ExecReload live-retune — standing non-goal.
44. CONTRIBUTING.md + issue templates — when external contributors appear.
45. SECURITY.md — when the audience grows.
46. CODEOWNERS — single-maintainer, skip.
47. Renovate-vs-dependabot final call — only if dependabot annoys.
48. Pre-commit treefmt hook for local dev.
49. CI aarch64 on a real arm runner.
50. Demo capture: consider a longer recovery window so the webp shows the full slide-up (current 4.5 s tail may clip the 450 ms animation + bar reflow).

## g) Three questions I cannot answer myself

1. **The monitor question, again with new data:** at ~03:00 the live niri session (PID 5049) was healthy but had ZERO active outputs. Is the display intentionally dark overnight (→ the live render proof waits for the SystemNix switch or morning), or is the session supposed to have outputs and this is a real bug worth investigating (in which case I'd dig into niri's output state)? **→ answered 2026-10-17 — displayless by circumstance (owner on SSH; card1-DP-1 connected-but-disabled); live proof rides the switch**
2. **Trash the smoke leftovers?** `/run/user/1000/offline-banner.state` (01:44, written by an intermediate QML revision at a path no current code uses), `/tmp/qsprobe`, `/tmp/uvroot`, `/tmp/offline-banner-demo/` — I read them all as same-session scratch; confirm they have no forensic value before I trash them (fleet rule: `trash`, never `rm`). **→ executed 2026-10-17 as the stated default — all four trashed; live dir /run/user/1000/offline-banner/ kept**
3. **Versioning intent for this batch:** the journal line format is a user-visible contract change (scripts grepping the old prose lines would break — unlikely but possible). Fold into `[Unreleased]` until the SystemNix switch lands, or cut v0.1.1 now that the release runbook exists? My default if unheard: `[Unreleased]`, no tag. **→ default taken — [Unreleased], no tag; v0.1.1 decision escalated to owner (10:40 report §g-1)**

---

## Return-state observations (09:36, not researched per instructions)

- Working tree clean; ~11 commits landed after my window, including two non-auto commits from other sessions ("website CI never started — secrets not allowed in step ifs", "stop tracking HyperFrames tool state in website/video") and new top-level `website/` + `assets/` dirs.
- `dprint.json` exists again, contradicting the AGENTS Hard-rules line recording its 2026-10-17 removal (§f-27).
- The TODO_LIST LICENSE edit that was uncommitted at my session start is gone from status (committed by the daemon at some point); whether the other session's commits preserved my AGENTS/README/flake changes verbatim was NOT verified — the working tree contains them as I left them, but a diff review against my intended end-state is part of §f-6.

*Point-in-time snapshot; sections follow the a–g dispatch shape. When bringing this report current, use docs-health ANNOTATE.*
