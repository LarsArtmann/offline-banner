# Status — docs-health audit, checkpoint mid-pass · 2026-11-23 00:52 CET

**Created:** 2026-11-23 00:52 CET · Crush (glm-5.3) docs-health AUDIT session · backlog basis: TODO_LIST @ `46da5dc` (before the rewrite), the 15 live status reports, the 2 live plans, and the live evo-x2 unit.

**Session scope:** the owner instruction was "view all dated files, execute the docs-health skill properly, make TODO_LIST / CHANGELOG / AGENTS / README / ROADMAP / FEATURES / `docs/DOMAIN_LANGUAGE.md` superb and up to date". This report is a CHECKPOINT, written on the owner's request while the pass is roughly one third done and the working tree is mid-edit. **Nothing is committed or pushed by this session.** Read §b first: the tree is not in a pushable state.

Note on the brief: the glob `**/2026-0*` matches zero files (the repo's history starts 2026-10-16); it was read as "every dated 2026 snapshot" — 15 live status reports and 2 live plans. Archived files were not opened (the skill forbids it without a gate flag); one archived report was flagged by the audit-all replay and is named in §a5.

## a) FULLY DONE (verified)

1. **Skill loaded before any action**: `docs-health/SKILL.md` in full plus the build, harvest, verify, agents-quality, health-report, ownership, resolving-items and common-mistakes references and all seven templates. Mode: AUDIT (BUILD + HARVEST + VERIFY, plus ANNOTATE for the reports).
2. **Baseline battery taken before the first edit** (CI-pinned docs-gates `e305834`): freshness PASS, audit-all PASS (0 unharvested over 27 reports), routing PASS (0 unrouted), **annotate FAIL (1 finding)**, **cadence FAIL** (15 unarchived, oldest 24 days old). Both red gates pre-date this session — see §a6.
3. **Every living doc read in full**: TODO_LIST (92 lines, 71.6 KB), CHANGELOG, FEATURES, README, ROADMAP, AGENTS; `module.nix` options, header doctrine and journal vocabulary for the glossary.
4. **Every live report analysed with a per-item verdict table**: 13 reports via three reader passes (11-17 21-46, 11-18 11-09 / 11-16 / 13-26 / 19-22 / 21-10 / 21-54 / 23-05; 10-29 14-06; 11-05 18-52 / 19-25 / 19-56 / 20-10) and the two newest (23-08, 23-40) read directly; both live plans (211 items). Roughly 640 work items carry a LANDED / OPEN-TRACKED / OPEN-UNTRACKED / NOT-A-TASK / OWNER-DECISION verdict with evidence.
5. **TODO_LIST.md rebuilt** (the only file this session has changed): 72 rows (65 of them closed `[x]` rows carrying closure narratives — 73% of the file was finished work) became **21 open rows**: 7 carried (switch-dependent bar wiring, second-output proof, owner ears, TS7 watch, daemon claim-awareness, plus the merged stale-tell and forced-outage ears), 4 owner decisions (D4 BuildFlow, v0.2.3, sandbox adoption, daemon policy), 10 agent-ready rows harvested from the reports. Cross-repo rows are tagged `(repo: …)`. A copy of the old file sits at `/tmp/ob-docs-health/TODO_LIST.old.md` and in git at `46da5dc`.
6. **Root causes of the two red baseline gates found**: (a) annotate — the daemon's sweep `46da5dc` (2026-11-23 00:11) re-flowed markdown and stripped two spaces around inline code in `docs/status/2026-11-17_21-46_…md:16`, re-corrupting the exact line the 2026-11-18 session had repaired; the trigger is a backslash-escaped backtick inside inline code, a shape that still exists at `23-40_…md:55` and `:75`. (b) cadence — the 10-29 postmortem is 24 days old (threshold 21) and 15 reports sit unarchived (threshold 15); the four 11-05 reports turn 21 days old on 2026-11-26.
7. **Freshness-gate blind spot found**: the gate only recognises a `## f)` heading. The newest report (23-40) uses `## f. NEXT`, so its 30 next-items were never checked by freshness or audit-all ("has no §f section — nothing to check").
8. **Live state verified on evo-x2** (read-only: journal, state file, ledger, the running unit's store QML): the unit auto-started at boot (`Nov 22 20:51:37 … Started Yellow offline banner`, zero `Failed at step`) — that closes the reboot leg of the old "live-verification debts" row with real evidence. Ledger holds 34 lines — but see §b7: tonight's flapping outage wrote six overlapping entries, so that count is inflated.
9. **Session claim recorded** in `docs/status/.session-claim` (gitignored) per the parallel-session protocol; all earlier claims were > 2 h old.

## b) PARTIALLY DONE

1. **The working tree is mid-edit and NOT pushable.** `git status`: only `TODO_LIST.md` is modified. With the closed rows gone, the audit-all replay reports **7 regressions** (was 0) — §f items in five reports that matched living docs only through the deleted closure narratives: `10-29_14-06` §f34 (failureThreshold — declined in the item itself) and §f49 (CI change line in the Website workflow header); `11-05_19-25` §f16 (S3 manifest-lock hook) and §f24 (tag-trigger decision — landed: no tag trigger); `11-17_21-46` §f5 and `11-18_13-26` §f13 (both the D3 backfill decision — landed: accept the gap); archived `10-17_10-40` §f50 (markdown hand-formatted — decided). All seven have a known verdict; none is annotated yet.
2. **HARVEST is incomplete**: the rebuilt TODO carries the items verified by hand and by the 11-17/11-18 reader passes. The 10-29 / 11-05 reader pass finished after the rewrite and adds roughly ten candidates not yet rowed or declined (website docs drift gate, `ubuntu-latest` on the Website jobs, a release-age / stale-lockfile CI assert, landing screenshots, a real-ledger fixture and the empty-ledger `jq` check, `pnpm audit`, the zizmor online-audit decision, the S3 hook, the `.crush` backup check). The 23-08 report (50 next-items) has no per-item verdict table yet — both verifier dispatches for it died on rate limits.
3. **ANNOTATE not started**: the verdict tables exist, no report line has been struck in this session. Roughly 760 unmarked numbered lines sit in the 15 live reports.
4. **Archive ritual not started**: targets are the age-overdue 10-29 postmortem, the three archive-ready 11-05 reports (18-52, 19-25, 19-56), and 21-46 once annotated.
5. **VERIFY findings compiled, fixes not applied.** With evidence, per doc: FEATURES — presentation rows still say "real-monitor proof pending" although the 2026-11-18 capture and the click-dismiss proof closed them; "Flake checks (11 gates)" vs 12 on x86_64 (`nix eval` of `checks.x86_64-linux`); "Boot-level VM proof … not a CI gate pending D1" (D1 decided, it is a gate); Planned rows for the real-monitor render and the click-dismiss harness are done; the reboot row is proven (§a8); "Release (v0.1.0)" while v0.2.2 is tagged; "systemd unit … reboot/re-login unproven"; no row for shell compatibility or the smoke app; re-verification stamp stops at 2026-11-17. README — "sway … expected but untested" vs sway CI-proven headless; "When NOT to use: … history … non-goals" contradicts the shipped outage ledger; state-file key list misses `demo`. ROADMAP — theme 3 still says the VM test "awaits the D1 decision"; non-goal "no history" contradicts the ledger; no home for the owner questions. AGENTS — 41.5 KB (the skill's budget flags > 30 KB as bloated; hundreds of date and hash anchors); claims "no dprint.json in this repo" while `dprint.json` is tracked; SystemNix consumer state stale (lock is at `412e553`, not v0.2.1); demo-video toolchain "verified under 0.9.52" while the manifest says `^0.9.82`; no pointer to a domain glossary. CHANGELOG — `[Unreleased]` lacks the ci-watch sentinel (added after the v0.2.2 tag) and the lock bumps; released sections lack minor CI/dependency bullets (left alone under the append-only rule).
6. **Two repo-integrity problems found, not fixed**: `website/video/package.json` demands `hyperframes ^0.9.82` (swept by the daemon's `46da5dc`), the lock pins 0.9.52 and `node_modules` holds 0.8.231 — a frozen install fails, and 0.9.82 only clears the 24 h release-age gate at 2026-11-23 22:51 CET; the same sweep bumped `flake.lock` (nixpkgs `0490633` → `2786a2a`, treefmt-nix; quickshell stays 0.3.2 on both — verified). Both are rowed in the new TODO and questioned in §g3.
7. **New product bug found while verifying the ledger (in no TODO row yet).** One flapping outage tonight (00:06:56 → 00:11:33, icmp down throughout, tcp flapping) wrote SIX ledger entries that all start at the same `from` (durations 22, 50, 79, 160, 204, 277 s). Every time the phase left `offline` for a single probe the banner hid and appended `outage ended from=<original start>`; when the phase returned to `offline` the outage resumed with the old `since` (journal: `state=shown … failures=13/2` — the counter never reset). Ten entries exist since 00:05 for about five real episodes, and summing `durationSec` overcounts offline time (792 s logged against a 277 s span). The doctrine is one entry per COMPLETED outage: the start is tied to the icmp failure run, not to the offline phase. Every "N ledger entries" figure in FEATURES, AGENTS and the reports inherits this doubt.

## c) NOT STARTED

1. `docs/DOMAIN_LANGUAGE.md` — does not exist; BUILD not begun (vocabulary already collected from `module.nix`).
2. Fixes to README, FEATURES, ROADMAP, CHANGELOG, AGENTS (list in §b5).
3. Normalising the 23-40 report's `## f.` heading to `## f)` and removing the backslash-backtick shape from `23-40:55` and `:75`.
4. `nix fmt`, `nix flake check`, the closing battery run, the inline health report (Accuracy + Fitness).
5. Cosmetic: the `module.nix` header carries the INDEPENDENT LEGS / SMART DISPLAY doctrine twice, and two comment lines are glued at "not on it. DISMISSABLE:".
6. Execution of any TODO row (not asked).

## d) TOTALLY FUCKED UP (own goals, all mine)

1. **I dispatched four subagents at once**; the provider rate-limited and five dispatches died (`reader-status-c`, `reader-status-a`, `verifier-2340`, `verifier-2308` twice). Net loss: the 23-08 and 23-40 per-item verification never ran through a reader; I verified about fifteen 23-40 leads by hand and none of 23-08's fifty.
2. **I stopped two readers a moment before the owner said "let the current ones finish"** — `reader-status-c2` had about ten minutes of work in flight. Both were re-run on `glm-5.3-flash` and finished, so nothing is missing, only late.
3. **I rewrote TODO_LIST.md before the annotations that depend on it existed**, turning a green audit-all into 7 regressions. Defensible only because nothing is pushed; the daemon may sweep the half-done file into a local auto-commit at any minute (never pushed by the daemon).
4. **Order of work**: I spent the first hour on verification and reading and wrote one of seven deliverables. The reports' verdict tables are the expensive, reusable part — but the owner sees one changed file.
5. **CI state of the pushed HEAD was not checked** (`gh run list`): the local battery is red on annotate at `46da5dc`, so the Checks `workflow-lint` job on master is expected red and ci-watch is expected to page — assumed, not confirmed.

## e) WHAT WE SHOULD IMPROVE

1. **Annotate first, then delete**: when a TODO rebuild removes rows that reports lean on for token matches, strike the report items before the rows go, and run the battery between the two steps.
2. **One subagent lane for readers, one for verifiers, never more than two** — the rate limit is real; simple reading goes to `glm-5.3-flash` (owner rule, 2026-11-23).
3. **Checkpoint reports must state the tree state in the first paragraph** — a reader must never have to reach §b to learn "do not push".
4. **The freshness gate should accept `## f.` as well as `## f)`** — or the status-report template must pin the `f)` shape; the newest report's next-list silently escaped both freshness and audit-all.
5. **Keep the backslash-escaped backtick out of markdown** (use a double-backtick code span): it is the sole trigger of the daemon's space-stripping reflow, and it has now corrupted the same line twice.

## f) NEXT (resume plan for this pass, in order)

**Owner window:**

1. SystemNix switch on evo-x2 — the deploy row at the top of the rebuilt TODO_LIST: the lock is at `412e553`, the running unit is pre-fix (journal: `phase=degraded` and `degraded dwell expired` in the same second at 2026-11-22 23:10:51).
2. After the switch: bar-side consumer live wiring + stale-tell proof, second-output proof, owner ears on the 12 cues, the four owner console one-offs — all rowed in TODO_LIST.

**New bug (agent, highest value — found by this session, §b7):**

3. Row and fix the ledger double-entry: an outage start that survives a phase change makes every offline→degraded blip append an overlapping entry (six entries for one outage tonight). Fix plus a `probe-transitions` scenario — icmp down, tcp flapping, dns up must yield ONE entry whose `from`/`to` span the episode — then re-count the live ledger.

**Resume the pass (agent, on "go"):**

~~4. Annotate the seven audit-all regressions named in §b1, then the 15 live reports' unmarked work items from the three reader verdict tables (`annotate.go status-items`, `emit-keys` keys, `--verify` before every write).~~ done at `e5913f4`, `640ac96` — the four 11-05 reports annotated by the resumed pass (99 items), 10-29 (67 verdicts) and 21-46 (66 verdicts) this session; gates CLEAN
~~5. Harvest the remaining candidates from §b2 into TODO_LIST rows or inline declines (declines need a reason a later session can re-evaluate).~~ done — the rebuilt TODO_LIST carries every harvested candidate; declines recorded in the applied verdicts
~~6. Archive ritual with gates BEFORE `git mv`: `check-rows --strict` + `bare-rows` + the strike-pair completeness grep; `> **Live remainder:**` banners; index rows and a per-file manifest in the status README.~~ done — six reports archived 2026-11-23: gates ran BEFORE git mv, evidence tables ledger-marked, Live-remainder banners, index rows + manifest; cadence ARCHIVE-HEALTHY
~~7. Normalise the 23-40 heading to `## f)`; repair `21-46:16`; remove the backslash-backtick shape from `23-40:55` and `:75`.~~ done at `e4a5a7a` — 23-40 heading normalised to f), the rule-F backslash-backtick shapes removed (21-46:16, 23-40:55/:75)
~~8. FEATURES: flip the proven rows, recount the checks from `flake.nix`, drop the finished Planned rows, add shell-compatibility and smoke-app rows, re-stamp the audit.~~ done at `d7f5158` — proven rows flipped, checks recounted (12 x86_64 / 11 aarch64 via nix eval), finished Planned rows removed, shell-compat + smoke rows added, re-stamped
~~9. README: sway CI-proven wording, the "history" non-goal contradiction, the `demo` state key.~~ done at `d7f5158` — sway CI-proven wording, the history non-goal rewritten, the demo state key documented
~~10. ROADMAP: theme 3 D1 line, the "no history" non-goal, an "Open questions" home for the owner questions.~~ done at `b8a8fc6` — theme 3 states the decided D1 and the honest compositor register; both non-goals fixed; Open questions added
~~11. CHANGELOG `[Unreleased]`: ci-watch sentinel, lock bumps, dependency-refresh bullet.~~ done at `90618d0` — ci-watch sentinel, the flap fix, the dependency repairs, D4, and the docs-pass bullets under [Unreleased]
~~12. AGENTS: factual drift first (dprint.json, SystemNix lock, video toolchain), runbook additions (post-switch click-dismiss ritual, audible-cue journal signature, foreign-commit and push-gate rules), then the size decision from §g1.~~ done at `90618d0` — factual drift fixed, the three postmortem rules landed, runbook additions, pruned to ~29 KB with narratives moved verbatim to docs/agent-notes.md
~~13. BUILD `docs/DOMAIN_LANGUAGE.md` from `module.nix` (legs, phases, debounce, dwell, outage, ledger, cue, re-arm, state file, consumer, smoke transient, env contract).~~ done at `9698cda` — built from module.nix vocabulary (legs, phases, debounce, dwell, outage, flap, latch, ledger, cue, re-arm, state file, seams, unit-managed env)
14. Closing gates: docs battery, `nix fmt`, `nix flake check`, then re-split the daemon's sweep if it took the half-done TODO and the commit is still unpushed; push only on green.
15. Inline health report (Accuracy + Fitness) with the as-found scoring.
16. Optional cosmetic: collapse the duplicated doctrine block in the `module.nix` header (comment-only).

## g) QUESTIONS FOR THE OWNER (cannot figure out myself)

1. **AGENTS.md size policy.** The skill scores AGENTS.md as bloated above 30 KB (it fails the endurance test on hundreds of dated incident narratives and commit hashes). Pruning to roughly 15–25 KB keeps every current rule, gotcha and runbook and moves the incident history to the reports and CHANGELOG, where it already lives — but it rewrites the dense style every previous session built. Prune to the skill's budget, or keep the dense file and fix facts only?
2. **The half-done tree.** The TODO rewrite alone leaves the battery red (§b1). On "go" I continue to a green tree; say "revert" instead if you want TODO_LIST.md restored to `46da5dc` right now so master and any daemon sweep stay green.
3. **Were the two dependency bumps in the daemon's `46da5dc` yours?** `website/video/package.json` → `hyperframes ^0.9.82` and the `flake.lock` bump. If yes, the lock must be regenerated and validated once 0.9.82 clears the age gate (rowed); if the daemon did it on its own, it is one more data point for the daemon-policy decision row.

— Verification at write time: `date` = 2026-11-23 00:52 CET; tree = `TODO_LIST.md` modified only; battery = annotate FAIL (1, pre-existing), cadence FAIL (pre-existing), audit-all REGRESSION 7 (caused by this session's TODO rewrite, verdicts known), freshness PASS, routing PASS. No commit, no push.
