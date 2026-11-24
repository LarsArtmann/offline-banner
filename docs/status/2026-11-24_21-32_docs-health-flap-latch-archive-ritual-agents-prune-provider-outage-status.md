# Status — docs-health pass resumed: verdicts applied, archive ritual, AGENTS prune, flap-latch fix, provider outage · 2026-11-24 21:32 CET

**Created:** 2026-11-24 21:32 CET · Crush (glm-5.3) docs-health AUDIT session, resumed on the owner's "whole todo list" order · backlog basis: TODO_LIST @ `9698cda`, the 11 live status reports, the battery at `e305834`, and this session's own commits `c835d62` → `5040a3f`.

**Tree state — read this first.** HEAD `5040a3f`, origin/master `b6c5add`: **8 commits unpushed** (nobody pushed since `b6c5add`; origin CI is still red on the OLD tree's formatting job from `b6c5add` itself). Working tree clean, but **`5040a3f` (a daemon sweep) committed my `set -x` debug line into the WRONG check's script** (`flake.nix:770` — a probe of another check, not probe-transitions): that line is a live defect this session introduced and must come out first (§f1). The flap-latch fix (`4e91642`) is committed but **`checks.x86_64-linux.probe-transitions` is RED locally and undiagnosed** (§d6). All prior session claims in `docs/status/.session-claim` are > 2 h old = void per protocol; this session must re-claim before touching the queue. Session stopped here on the owner's order.

Scope: only this session's run (2026-11-23 02:36 → 2026-11-24 21:29, spanning a host reboot 2026-11-23 ~20:46 and a ~23 h wall-clock gap between turns). It resumes the checkpoint report `2026-11-23_00-52_…` and the resume report `2026-11-23_02-16_…` (both now largely struck).

## a) FULLY DONE (verified)

1. **CI hygiene landed.** `flake.nix` formatted (`c835d62`); the `formatting` check builds green; **both `website.yml` jobs pinned to `ubuntu-24.04`** (the 2026-10-29 drift class, item 12 of the 10-29 postmortem).
2. **The three postmortem rules + the release-runbook NOT-verified step landed in AGENTS.md** (`8a2d0c3`): reproduce-CI-locally, pixels-not-builds, NOT-verified-in-release-notes — the four artifacts the withheld `10-29` spec demanded, landed BEFORE its spec was applied.
3. **D4 EXECUTED** (`8a2d0c3`): a real skip-only `.buildflow.yml` (skips `dprint-format`, `prettier-format`, `nix-fmt` with rationale; `config lint` clean; dry-run shows all three `skipped via skip_steps config`), the BuildFlow-dropped `dprint.json` deleted and gitignored. This kills at the source the markdown-reflow damage class that corrupted annotated reports twice.
4. **`build.py` recreated** (lost with the `/tmp` wipe — see §d7) and hardened: continuation-line strikes extended to the column-0 hard-wrap shape (corpus ground truth at 10-29 item 10), durably housed in `docs/status/.session-work/` (gitignored) instead of `/tmp`.
5. **The 10-29 postmortem resolved: 67 verdicts applied** (`e5913f4`) + 113 continuation lines struck, every verdict reviewed against its item before the write. Includes §f34 (declined in-item, YAGNI — closes an audit-all regression), the D4 item upgraded from routed to DONE after the artifact landed, and item 12 annotated only after the runner pin was real.
6. **The 21-46 corpus sweep resolved: 66 verdicts applied** (`640ac96`) after full review — 10 hyperframes routes re-pointed at the CURRENT TODO row (the manifest/lock split was repaired mid-pass), four "pinned e305834" verdicts reworded (the builder's hash-stripper ate the cross-repo rev), and two gate-hostile literal-tilde code spans repaired (they made the freshness resolver skip the lines).
7. **The four audit-all regressions closed** (10-29 §f34; 21-46 §f5 + 13-26 §f13 `done at 7a4df29` D3 accept-the-gap; archived 10-17 §f50 decided — markdown stays hand-formatted, D4 executed). **Audit-all is FRESH at 0 unharvested across all 29 replayed reports.**
8. **Annotate gate CLEAN at 875+ struck items, 0 findings.**
9. **Archive ritual executed for six reports** (10-29, the four 11-05 reports, 21-46): `check-rows --strict` + `bare-rows` gated BEFORE `git mv` (all clean), the three accomplishment/evidence record tables ledger-marked (`<!-- check-rows:ledger -->` — the sanctioned exemption), `> **Live remainder:**` banners naming every open tail, six index rows + per-file manifest in `docs/status/README.md`, post-move strike-completeness grep clean. **Cadence: ARCHIVE-HEALTHY (11 unarchived, oldest 6 days).** The one `--strict` FAIL in the archived dir is a PRE-EXISTING 2026-10-29-era file — the doctrine explicitly forbids whole-archive-dir gating; this sweep's moves were gated individually.
10. **FEATURES.md re-verified and updated** (`d7f5158`): the 2026-11-18 real-monitor + click-dismiss proofs folded in (strip and dismiss rows flipped FULLY_FUNCTIONAL), checks recounted from the flake via `nix eval` (**12 on x86_64, 11 on aarch64** — vm-smoke deliberately x86_64-only), the three finished Planned rows removed, shell-compatibility + smoke-app rows added, header re-stamped 2026-11-23.
11. **README.md drift fixed** (`d7f5158`): sway CI-proven wording, the "history" non-goal contradiction rewritten (the ledger is real), the `demo` state key documented, one-entry-per-completed-outage behavior stated.
12. **CHANGELOG `[Unreleased]` completed** (`90618d0`): ci-watch sentinel, the flap-latch fix, the two dependency-manifest repairs (with the emnapi rejection evidence), the Website runner pin, D4, the probe-transitions polling helpers, and the docs-pass bullet.
13. **AGENTS.md pruned 41.5 KB → ~29.6 KB** (`90618d0` + `5040a3f`), inside the guide's "15–30 KB acceptable" band: every rule, contract, runbook and decision kept (several condensed to current truth), and **all dated incident narratives moved VERBATIM into the new `docs/agent-notes.md`** (25 KB, 21 labelled sections). Runbook additions: the post-switch ritual (smoke + click-dismiss + journal sweep with the cue-FIRED signature), the foreign-commit/push-gate rules.
14. **`docs/DOMAIN_LANGUAGE.md` BUILT** (`9698cda`) from `module.nix` vocabulary — legs, debounce, phase, ladder, outage, flap, `outageOpen` latch, dwell, re-arm, dismissal, state file, ledger, cue, demo, probe seams, unit-managed env, plus bounded-context rows (debounced decision facts vs raw counters) and deprecated terms. **Freshness gate: FRESH** — the last open §f item this closed.
15. **TODO_LIST refreshed** (`9698cda`): the D4 decision row deleted (done; lives in CHANGELOG), the native-arm-runner row added (hosted `ubuntu-24.04-arm` runners verified free for public repos — routes 18-52 §f39), 25 open rows.
16. **The ledger double-entry bug FIXED in the product** (`4e91642`, module.nix): an `outageOpen` latch opens on the entry into `offline` (never in demo — probes succeed there, `firstFailedAt` stays 0) and closes ONLY on the entry into `online`; the ledger close AND the show/recover cues ride the latch; `banner state=` journal lines unchanged. This is the six-overlapping-entries live bug (2026-11-23 00:06: one `from`, durations 22/50/79/160/204/277 s, 792 s logged against a 277 s span).
17. **A dedicated flap scenario added** to `probe-transitions` (icmp down throughout, tcp flapping across its debounce, dns up → exactly ONE entry spanning both hops + exactly one cue pair, negatives on both hops), and the two ledger assert helpers parametrized by file with a fresh-file-reads-as-ZERO fix.
18. **The main/leg/icmp+tcp/link/demo scenarios all still pass** under the latch (proven by the failing drv's own log reaching the flap section with the correct single entries: main `reasons=[net,tcp,dns,link]`, legs `[tcp,dns]`, icmp+tcp `[net,tcp]`).
19. **The two docs-health pass reports' §f items struck as they completed** (00-52: 11 items; 02-16: 12 items + the earlier §f5) — via emit-keys → spec → verify-with-line-drift-guard → atomic write. **The drift guard earned its keep twice: it refused two wrong-line writes** (a stale line map and a not-yet-existing commit hash), both caught before any mutation.
20. **module.nix header dedupe (comment-only)** (`4e91642`): the duplicated INDEPENDENT LEGS/SMART DISPLAY doctrine collapsed, the glued `DISMISSABLE:` line un-glued. Verified comment-only (no QML string touched, `nix fmt` clean).

## b) PARTIALLY DONE

1. **`checks.x86_64-linux.probe-transitions` is RED** with the flap scenario in place: the builder exits 1 **silently** (zero log lines, even under `-L`) while every sibling check builds green post-reboot (unit-verify ✓, render-smoke ✓ — same sway+quickshell stack, shell-content ✓). The flap scenario itself is half-proven: the first failing run got THROUGH both flap hops with the latch holding (no `outage ended`, ledger unchanged) and died only at my own wrong `since` assert (`since` is offline-gated BY DESIGN — null in degraded; the assert was removed), then the silent-death regime started. Not yet diagnosed (§f1-2); the instrumented-build attempt misfired (§d8).
2. **The verifier lane is dead — all four providers.** zai (session provider) rate-limited until 11:25, hyper no credits, gemini depleted, huggingface no credits. Zero verdicts produced by subagents this session; the 23-08 dispatch was retried across three providers. Verification of the remaining nine reports + two plans (~670 numbered lines) must be self-done or provider-funded (§g2).
3. **Annotations for the remaining live reports not started** (23-08 109 lines, 21-54 94, 19-22 99, 23-40 71, 11-16 72, 11-09 47, 13-26 53, 21-10 5, plans 125+99 — counts from this session's regenerated numbered lists). The battery is green WITHOUT them (their open items pass audit-all), so this is completeness, not health.
4. **AGENTS.md at 29.6 KB** — inside "acceptable" but above the plan's ≤ 25 KB hope; further squeezing would start cutting procedures, which I declined to do.
5. **The `set -x` debug line** sits committed in the wrong script (§a-note) — removal is a two-minute edit, not yet done (stop order arrived mid-diagnosis).
6. **docs-gates `run .` matrix**: freshness PASS, audit-all PASS (0), annotate PASS, cadence PASS — **routing not re-run in the final state** (was PASS at mid-pass) and the full `nix flake check --all-systems` never ran (blocked on the red probe check).

## c) NOT STARTED

1. Self-verification of the nine live reports + two plans (blocked on §b2/b3).
2. The final pass report + inline Documentation Health Report (Accuracy + Fitness) — this report's successor, after the remaining steps close.
3. Release of the session claim (my 11-23 claims are void; a fresh claim is needed for any resumed work).
4. `nix flake check --all-systems`, the closing battery, the push (owner-gated), and CI confirmation on the pushed HEAD — all wait on §b1's red check.
5. Index rows for the 00-52/02-16 pass reports in `docs/status/README.md`'s live-index section (if one exists — not checked).

## d) TOTALLY FUCKED UP (own goals, all mine)

1. **I committed a debug line into the wrong check.** The `set -x` instrumentation anchored on the FIRST `export XDG_RUNTIME_DIR="$PWD/runtime"` in `flake.nix` — which belongs to an earlier check's script, not probe-transitions — and the daemon swept it into `5040a3f` before I noticed. Both the anchor mistake (no post-edit verification of WHERE the edit landed) and the committed state are mine.
2. **I edited the harness helpers against a stale copy** — my first multiedit failed "file modified since last read" (the exact disk-truth violation the corpus itself codifies), costing a re-read and a retry.
3. **The AGENTS split clobbered the Git protocol paragraph.** My replacement map keyed `134` to a heading, silently REPLACING the 2.2 KB Git-protocol paragraph instead of condensing it — content loss, restored only because the pre-split text lived in this conversation. The same off-by-one (line numbers measured BEFORE my own earlier AGENTS edits shifted them) produced the SystemNix stub/original duplication and the 53/54 note-label swap; all repaired, but the repair took three tool calls the map should never have needed.
4. **I wrote line-numbered verdict specs from memory instead of re-deriving them.** The 02-16 strike's first attempt had SIX wrong-line rows — the line-drift guard refused the write (correct tooling, wrong operator discipline). Same class as §d3.
5. **I cited a commit hash that did not exist** (`7f5ab2c` in the first 00-52 spec, before the fix commit was made) — my own `cat-file` assert caught it; the "no done verdict before the artifact exists" rule extends to hash citations.
6. **The flap scenario needed three build cycles to reach its current state**: the helper read a missing ledger file as `""` (not 0), my `since` assert contradicted the designed offline-gating, and the redirect-failure noise polluted the log. I never exercised the missing-file path before shipping the scenario — the cheapest possible unit test would have caught it offline.
7. **I trusted `echo RC=$?` after a pipeline** — reported `PROBE_BUILD_RC=0` on a FAILED build (twice) until switching to `PIPESTATUS`/direct rc. A green-looking lie in my own tooling.
8. **The instrumented-build attempt ran on a false anchor**: the python assert failed ("instrumented" never printed) and the background job built the UNCHANGED drv anyway, wasting a full build cycle — I bundled the edit and the build in one command without checking the edit's success.
9. **Four verifier dispatches died on provider billing/rate limits** (zai, hyper, gemini, huggingface) — ~40 minutes of wall clock. I should have smoke-tested the provider lane with one trivial dispatch before wiring the full protocol to it.
10. **I depended on `/tmp` for session-critical artifacts** (the predecessor's build.py, verdict TSVs, VERIFIER_PROMPT) — wiped mid-session (the host rebooted 2026-11-23 ~20:46; `uptime` confirms). Everything lost was reconstructible from git or conversation, and the replacements now live in the repo — but the lesson is durable: session work dirs belong in the repo.
11. **My 11-23 session claims went stale** (> 2 h = void) — the wall-clock gap between turns voided the whole claim file; a resumed session must re-claim before touching the queue (protocol-corollary: write claims with resumption in mind, not just liveness).

## e) WHAT WE SHOULD IMPROVE

1. **Re-derive line anchors immediately before every keyed write** — never from a measurement taken before intervening edits (§d3/§d4). The drift guard is the seatbelt, not the driver.
2. **Never cite a hash that `git cat-file` has not already accepted in THIS repo** — land the commit, then write the verdict.
3. **Exercise harness edge paths (missing file, empty file, wrong count) before a scenario ships** — the flap helper bug was unit-testable in one line.
4. **Nix build rc discipline**: capture `${PIPESTATUS[0]}` or drop the pipe; never echo `$?` after `| tail`.
5. **Smoke-test any external dependency (provider lane, network, tool) with a one-shot probe before building a workflow on it.**
6. **Session work dirs live in the repo** (gitignored) from minute one — `/tmp` is a lease, not storage.
7. **Verify WHERE an anchor edit landed** (line + enclosing symbol) before building on it — §d1 was a blind textual replace.
8. **The verdict-builder's hash-stripper silently rewrote verdict text** (dropping `e305834` from "pinned e305834") — verdict text should be frozen at review time with the strip logged, not applied invisibly.
9. **When a battery gate and an annotation canon disagree** (the `~~N. item~~` shape hiding item-starts from the annotate extractor — the 169 false-positive class), fix the corpus shape AND record the quirk for upstream (docs-gates candidate issue, verify-before-filing first).
10. **Claims must carry a wall-clock expiry the NEXT session can honor** — a claim that voids on a 23 h gap is worse than none.

## f) NEXT (in order — up to 50)

**Unblock the red check (agent, first):**

~~1. Remove the `set -x` debug line from `flake.nix:770` (the wrong check's script) — it is a committed live defect.~~ done at `29809f7` — removed; the re-split commit carries a real message
~~2. Diagnose the probe-transitions silent exit-1: instrument the CORRECT script (anchor inside the probe-transitions block, verify the landed location), rebuild, read the trace, fix the death point.~~ done at `0c54f9a` — root-caused via a location-verified set -x probe: stdenv set -euo pipefail turns a failed cat on a legitimately-absent flap ledger into a silent exit-1
~~3. Restore `checks.x86_64-linux.probe-transitions` green locally (the flap scenario asserts the full latch contract — this is the flap fix's proof).~~ done at `de11201` — probe-transitions RC=0; the flap scenario proves the outageOpen latch end-to-end
~~4. Re-run the full battery + `nix build` of every x86_64 check; `nix flake check --all-systems` (aarch64 eval-only is acceptable locally; CI proves the rest).~~ done — full battery all-pass; nix flake check green (x86_64 build incl. vm-smoke, aarch64 eval 11/11)
~~5. Commit the diagnostic + fix batch with a real message; re-split anything the daemon swept (check `git log` first).~~ done at `0c54f9a` — the fix batch committed with real messages; every later daemon sweep re-split

**Verdict work (agent, after the lane decision in §g2):**

~~6. Self-verify (or re-dispatch if funded): 23-08 (109 lines) → build spec → full review → apply → gate.~~ done — self-verified after the lane died 4-of-5 dispatches even at concurrency 1; 98 verdicts, hashes verified
~~7. Same for 21-54 (94), 19-22 (99), 23-40 (71), 11-16 (72), 11-09 (47), 13-26 (53), 21-10 (5).~~ done — 21-54 75, 19-22 80, 11-16 54, 11-09 42, 13-26 27, 21-10 5 verdicts applied
~~8. Same for the two live plans (125 + 99; ledger-mark the F-tables per the planning-archive canon).~~ done at `3f54453` — both plans resolved; the F/subtask tables ledger-marked per the planning canon
~~9. Harvest every OPEN-UNTRACKED/QUESTION verdict into TODO rows or inline declines with reasons; ledger the dispositions in the final pass report.~~ done — the harvest ledger is in the 22-49 final report (17 rows, 2 ROADMAP ideas, 15 declines)
~~10. Re-run the battery after each apply (annotate + audit-all are the ones that can regress).~~ done — the battery ran after every apply; all five gates green at the end
~~11. Repair any rule-F (backslash-backtick) shapes the new strikes surface — three corpus-wide already; the shape is a known daemon-reflow trigger.~~ done — no rule-F shapes surfaced in this pass's strikes; annotate CLEAN throughout
~~12. Watch for the annotate-gate chain false-positive class (tilde-struck `N. item` rows absorbed under an open item's block) — fix on sight, log for upstream.~~ done — four chain false-positives fixed on sight (23-40 x2, 21-54 x1, 13-26 x1)
~~13. After the nine reports: annotate 21-46-era routed arrows if any TODO row titles changed again (the stale-arrow sweep).~~ done — six stale arrows repointed after the eyeballs-row retitle; gates re-run clean
~~14. Write the final pass report with the full harvest ledger; annotate 00-52/02-16 §f remainders (`f1` flake check, `f2` CI re-run, `f6` verifiers, `f7` harvest, `f18-20`) as they close.~~ done — the final pass report 2026-11-24_22-49 carries the full ledger
~~15. Print the inline Documentation Health Report (Accuracy + Fitness scores, per-doc findings, visible math).~~ done — the inline Documentation Health Report is in the 22-49 report with visible math
~~16. Index rows for the 00-52/02-16 reports in the status README's live section; release/re-claim the session claim file.~~ done — 00-52/02-16/21-32/22-49 rows added to the status README

**Owner window (the deploy row and its tails):**

17. Push master (8 commits, real messages, once §f1-4 are green) — or hand the push to the owner on request (§g1); watch both workflows on the pushed HEAD (ci-watch is presumably paging on the red origin tree).
18. Confirm aarch64 `probe-transitions` green on the pushed HEAD (the flap-latch + polling helpers under real CI cadence).
19. SystemNix switch on evo-x2 (the deploy row — lock is at v0.2.1; the unit runs pre-ladder-fix gen 995's successor).
20. Post-switch ritual: `nix run .#smoke`, `scripts/click-dismiss-proof.sh`, journal sweep (zero `Failed at step`, fresh heartbeat, cue-FIRED signature).
21. Bar-side consumer: wire the `systemnix-banner` DMS plugin live + the stale-tell proof.
22. Second-output proof (owner console).
23. Owner ears: audition the 12 cues; re-confirm the `chime` default after a real outage.
24. Owner console one-offs: apply the staged IAM grant in the domains repo, post the launch drafts, upload the social preview, the `.crush` backup check.
25. Cut v0.2.3 per the runbook (fold `[Unreleased]`, execute-the-app step 1b, tag, curated notes WITH the NOT-verified section), then re-lock SystemNix to the tag.

**Agent-ready TODO rows (unchanged, in queue order):**

26. `docs-site-drift` flake check (the website has no drift gate).
27. Ledger recipes fixture gate.
28. The astro bump emnapi investigation (blocked upstream; watch @emnapi/runtime).
29. Vendored OG font (drop the build-time network fetch).
30. (repo: crush-config) lessons entry: an auto-commit daemon must never own dependency manifests.
31. checks.yml `concurrency` (cancel superseded runs).
32. Smoke app `--print` runtime-override assert.
33. Click-dismiss harness hardening (re-verify the strip at the click moment).
34. band-count.py synthetic-PPM fixture teeth.
35. Journal completeness gate (cue-fired line + state-write failures).
36. `shell-scripts` gate: glob `scripts/*`.
37. Deliberate `hyperframes` upgrade (now that the manifest is back on 0.9.52).
38. Website follow-ups: Omarchy dev-guide link stamp, og:description refresh, screenshot pass.
39. TS7 watch-row refresh cadence.
40. aarch64 CI on native hosted arm runners (new row; evaluate vs binfmt).
41. Daemon policy decision (owner): the S3 manifest-lock hook option, claim-awareness.
42. Sandbox adoption decision (owner): `PrivateDevices` / `MemoryDenyWriteExecute` (probe-evidenced survivable; 12 s demo ≠ soak).
43. Journal retention taste call (ROADMAP Open questions).
44. The `--no-verify` commit ack (ROADMAP Open questions).
45. Supervised first run of `docs-gates purge` (when the struck-row backlog is nonzero — a no-op today, deliberately not rowed).

**Fleet/upstream (repo: crush-config or docs-gates, only after verify-before-filing):**

46. docs-gates candidate issue: the `~~N. item~~ verdict` strike shape hides item-starts from the annotate extractor — struck chains under an open item can false-positive "no verdict marker" (source-level verified twice this session: 10-29:169, and the resolver skipping lines whose strike text sits inside code spans).
47. docs-gates candidate note: `emit-keys` accepts lines the resolver refuses (literal-tilde-in-code-span lines) — the asymmetry cost two repairs; align or warn.
48. crush-config lessons: formatter-stability check BEFORE mass annotation; never let a verdict builder silently rewrite verdict text.
49. crush-config lessons: session work dirs live in the repo, not `/tmp`; provider lanes get a one-shot health probe before protocol work.
50. BuildFlow upstream: skip non-covered repos by default (the zombie-class fix — D4 closed it HERE, the fleet still grows dprint.json).

## g) QUESTIONS FOR THE OWNER (cannot figure out myself)

1. **Push authority.** 8 commits sit unpushed; origin master is red (the old formatting job on `b6c5add`), so ci-watch is presumably paging on a tree whose fixes are already local. Once the probe check is green locally — do I push, or do you? (My default per the protocol: I do not push without your word.)
2. **The verifier lane is dead at every provider** (zai rate-limited, hyper/gemini/huggingface out of credits). The remaining nine reports + two plans (~670 lines) can be self-verified by this session (hours of context-heavy, lower-freshness work) or done properly by funded subagents. Fund one provider, or accept self-verification?
3. **The probe-transitions silent failure started exactly at the host reboot** (2026-11-23 ~20:46): builder exits 1 with a ZERO-line log while unit-verify, render-smoke and shell-content (same sway/quickshell stack) all build green. Do you recall anything that changed on this host around that reboot — a nix version bump, store prune, kernel/systemd update, or cgroup/sandbox policy change — that would kill one specific check's builder silently?

— Verification at write time: `date` = 2026-11-24 21:29 CET; tree = clean at HEAD `5040a3f` (the `set -x` defect is INSIDE this commit), origin `b6c5add`, 8 unpushed commits; battery = freshness FRESH, audit-all FRESH (0 unharvested/29 reports), annotate CLEAN, cadence ARCHIVE-HEALTHY (11 live, oldest 6 d); `checks.x86_64-linux.probe-transitions` RED (silent builder exit, undiagnosed); unit-verify/render-smoke/shell-content green; no push by this session; AGENTS.md 29.6 KB + `docs/agent-notes.md` 25 KB verbatim archive.
