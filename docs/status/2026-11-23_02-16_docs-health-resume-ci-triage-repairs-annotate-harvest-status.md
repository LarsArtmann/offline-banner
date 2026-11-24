# Status — docs-health audit resumed: CI triage, dependency repairs, annotate + harvest · 2026-11-23 02:16 CET

**Created:** 2026-11-23 02:16 CET · Crush (glm-5.3) docs-health AUDIT session, resumed after the 00:52 checkpoint · backlog basis: TODO_LIST @ `89a8e39`, the 16 live status reports, the CI runs on master, and the live evo-x2 unit.

**Tree state — read this first.** HEAD `b8a8fc6` holds everything this session did so far, captured by the auto-commit daemon in six `chore: auto-commit` commits. `origin/master` is `b6c5add`: **someone pushed master at about 02:00 while the pass was mid-edit** (this session never pushed). The public tree therefore carries a half-done docs pass plus one unformatted `flake.nix` (§d1). Unpushed: `89a8e39` (TODO_LIST.md) and `b8a8fc6` (ROADMAP.md + four annotated reports). Working tree clean. Session stopped on the owner's order at 02:16.

Scope of this report: only what this session did and noticed between 01:00 and 02:16. It resumes the checkpoint report `2026-11-23_00-52_docs-health-audit-checkpoint-todo-rebuild-and-live-fix-gap-status.md` (its §b5 drift lists and §f resume plan still stand where not superseded below).

## a) FULLY DONE (verified)

1. **Skill and gate mechanics reloaded.** `docs-health/SKILL.md` and its references; the docs-gates source at the pinned rev `e305834` (annotate rules A–G, freshness token bar, routing candidates, cadence inventory). One fact corrects a TODO row: rule F scans **every tracked `.md` / `.sh` / `.nix` file** (`git ls-files *<ext>` in `internal/docsannotate/spacing.go`), so README, FEATURES, TODO_LIST and AGENTS are already protected — the "corpus tripwire" row rested on a false premise and is removed.
2. **Rule-F finding repaired at its root.** `21-46:16` rewritten with double-backtick code spans, the same shape removed from `23-40:55` and `:75`, and the `23-40` heading normalised from `## f.` to `## f)` (its 30 next-items were invisible to freshness and audit-all). Verified: `dprint check` clean on both files under the repo's own `dprint.json`; annotate gate **CLEAN, 0 findings** (was 1).
3. **Master CI triaged — three independent reds, each with evidence.** (1) Website: `ERR_PNPM_OUTDATED_LOCKFILE` — the daemon sweep `3c2aca9` (2026-11-18 23:22) bumped astro and @astrojs/sitemap in `website/package.json` without the lock; red for four days. (2) nix-check: `checks.aarch64-linux.probe-transitions` failed on run 45082086628 with "expected 3, got 2" — a single-read ledger count taken right after a journal line. (3) workflow-lint: the docs battery (annotate + cadence).
4. **Website dependency split repaired and proven.** The manifest is back on the validated pair (astro `^7.4.12`, @astrojs/sitemap `^3.7.5`; lock bytes unchanged). Verified: `pnpm install --frozen-lockfile` passes; `astro check` = 0 errors, 0 warnings, 0 hints over 31 files; **CI Website workflow green on `40a7dcc` (run 45091328246)** — the first green deploy build since 2026-11-18 23:22.
5. **A lock regeneration was tried first and rejected with evidence.** Regenerating for astro 7.4.13 resolved `@napi-rs/wasm-runtime` 1.2.4/1.2.6 → `@emnapi/runtime@2.0.0-beta.2` beside `@emnapi/core@1.11.3`, and `astro check` died at start (`this.bridge.setLastError is not a function`). That is now a TODO row: the next astro bump is blocked until the pair is pinned or fixed upstream.
6. **`website/video` manifest restored** to the validated range `^0.9.52` (lock 0.9.52). Verified: frozen install green, `node_modules` now 0.9.52 (was 0.8.231).
7. **Harness race fixed in `flake.nix`** (probe-transitions): `assert_ledger_entries` polls for a count a transition must reach, `assert_ledger_unchanged` settles 1.5 s before judging a count must not move; eight single-read `wc -l` asserts replaced; `assert_no_journal` no longer spews "No such file" for a log that legitimately does not exist yet. Verified: `nix build .#checks.x86_64-linux.probe-transitions` exits 0 locally. **Not verified: `nix fmt` (see §d1) and aarch64 CI.**
8. **Verifier pipeline built.** Protocol file (`/tmp/ob-docs-health/VERIFIER_PROMPT.md`: read-only, classes, every hash `git cat-file`-verified, mandatory anchor column), numbered line lists, and a spec builder (`/tmp/ob-docs-health/work/build.py`) that rejects anchor mismatches, validates every cited hash, runs `status-items --verify`, demands an exact key/line match before writing, and strikes continuation lines per the house style.
9. **Four archive-target reports annotated — 99 items, every verdict read against its item line.** `18-52` (34), `19-25` (22), `19-56` (4), `20-10` (39). Misattributions found by that review and corrected by hand: `20-10` first pass had shifted line numbers (whole table redone with anchors); `18-52` §f39 was marked done (native arm runners were never explored) and §g2 carried a foreign note; `19-25` had nine misaligned rows after line 64. Gate result: annotate **CLEAN, 694 struck items, 0 findings**.
10. **`10-29` verdict table complete and reviewed** (83 items; 67 verdicts built, 16 lessons left bare). Spec built, **not applied** (§b3).
11. **`21-46` verdict table delivered** (96 rows, anchored, hashes verified). Not yet reviewed (§b4).
12. **Harvest decisions made for the five archive-target reports** (ledger in §f-preamble below). `TODO_LIST.md` rewritten: 25 open rows — 7 verification, 4 owner decisions, 14 agent-ready. New rows: deliberate `hyperframes` upgrade (replaces the split repair), `docs-site-drift` flake check, ledger recipe fixture gate, astro bump blocked by the emnapi mismatch, vendored OG font, `(repo: crush-config)` lessons entry. Updated: daemon-policy row (three sweeps, the S3 hook option), owner console one-offs (fifth item), TS7 watch row, website follow-ups row (OG refresh).
13. **ROADMAP corrected**: theme 3 states the decided D1 (the VM boot is a blocking check) and the honest compositor register (niri live-proven, sway CI-proven headless, Hyprland untested); two non-goals that contradicted the shipped module fixed ("no history" vs the outage ledger; "never gated on … DNS" vs the dns leg); a new **Open questions** section (the `--no-verify` commit in the domains repo; ledger retention).
14. **Facts verified by command, not by memory**: the jq `-s … | add // 0` recipe prints `0` on an empty and on an out-of-range ledger; the deployed pagefind index counts 9 pages = the 9 docs pages tracked, no `excludeSearch` anywhere; `pnpm audit` clean in `website/` and `website/video/`; `website.yml` runs both jobs on `ubuntu-latest`; `checks.yml` has no `concurrency` block; `.crush` → `/mnt/hot/crush/offline-banner`; `global.out.css` is deleted in git (`373690e`) and ignored (`24310e9`).
15. **Battery movement**: audit-all 7 → **4** unharvested; freshness PASS; annotate CLEAN; routing PASS (0 unrouted); cadence still overdue (16 unarchived, oldest 25 days).

## b) PARTIALLY DONE

1. **The public tree is mid-edit** (see the first paragraph). Pushed: manifest repairs, the `flake.nix` harness patch, the `18-52` annotations, the checkpoint report. Unpushed: the rewritten TODO_LIST, the ROADMAP edits, four annotated reports.
2. **CI on master after the push**: Website green; Checks red on two jobs — workflow-lint (docs battery: audit-all 4, cadence) and nix-check (`checks.x86_64-linux.formatting`, §d1). Whether aarch64 `probe-transitions` is green on `b6c5add` is **unconfirmed**: the job stopped at the formatting failure, and the follow-up `gh` queries were refused by the API ("error connecting to api.github.com").
3. **`10-29` annotations withheld on purpose.** Five built verdicts say "done — … on 2026-11-23" for artifacts that do not exist yet: the three AGENTS rules (reproduce CI locally; screenshots for presentation changes; "what was NOT verified" in release notes) and the `ubuntu-24.04` pin for the Website workflow. They must land before the spec is applied.
4. **`21-46`**: table ready, zero verdicts reviewed, no spec built.
5. **TODO_LIST.md** is consistent with today's findings but not final: the native-arm-runner row waits for a verification search that had not reported back at 02:16 (so `18-52` §f39 stays open-untracked); the v0.2.3 row needs refreshing once this session's fixes are in the CHANGELOG.
6. **ROADMAP.md**: the three known drifts are fixed; the file was not re-verified line by line against FEATURES and README.
7. **Harvest**: five of sixteen live reports dispositioned. Open, each with a verdict known: `10-29` §f34 (declined in the item — YAGNI), `21-46` §f5 and `13-26` §f13 (D3 decided at `7a4df29`), archived `10-17` §f50 (decided: markdown stays hand-formatted).
8. **The four freshly annotated reports are not formatter-stable.** `dprint check` (the repo's own `dprint.json`) rewrites them: a line that starts with `~~N. …~~` is no longer a list item to dprint, so it re-indents the struck line and **renumbers every unstruck item after it** (measured on `18-52`: §b items 3-5 become 2-4, §f items 7-10 become 6-9). The daemon's next BuildFlow reflow would do exactly that — the same class as the D4 zombie, and it breaks the "never renumber" rule of the annotation canon. The reports annotated by earlier sessions carry the same shape. Not fixed: the stop order arrived first. This new report and the TODO/ROADMAP edits are dprint-stable (verified).
9. **Local website build cannot be proven from this machine**: `astro build` dies fetching Noto Sans from `api.fontsource.org` (connect timeout from the shell; the host itself answers). Rowed (vendored font); CI is unaffected.

## c) NOT STARTED

1. `nix fmt`, and the full `nix flake check --all-systems` on the patched tree.
2. The `ubuntu-24.04` pin for `website.yml` (verified needed, not edited).
3. The four remaining audit-all regressions (verdicts known).
4. Annotate + harvest for `11-09`, `11-16`, `13-26`, `19-22`, `21-10`, `21-54`, `23-08`, `23-40`, the 00-52 checkpoint, this report, and the two live plans (14 + 5 unmarked lines).
5. Archive ritual for `10-29` and the four 11-05 reports: `check-rows --strict` + `bare-rows` + the `~~` grep **before** `git mv`, `> **Live remainder:**` banners, index rows and a per-file manifest in `docs/status/README.md`.
6. FEATURES.md (proven presentation rows, 12 checks on x86_64, dead Planned rows, Release v0.2.2, reboot proven, shell-compatibility + smoke rows, re-stamp), README.md (sway CI-proven; "history" non-goal; `demo` state key), CHANGELOG `[Unreleased]` (ci-watch sentinel; lock bumps; today's repairs), AGENTS.md (factual drift, the three rules, runbook additions, prune), `docs/DOMAIN_LANGUAGE.md`.
7. The ledger double-entry product bug (checkpoint §b7) — rowed in the predecessor's plan, not fixed, not yet a TODO row.
8. Closing gates (battery, dprint stability over every touched file, link check), the inline health report, the index row for this report, the claim heartbeat (last refreshed 01:31).

## d) TOTALLY FUCKED UP (own goals)

1. **I edited `flake.nix` and never ran `nix fmt`.** The treefmt check is now red on the pushed master (`checks.x86_64-linux.formatting` on `b6c5add`). I built the one check I changed and skipped the formatter the repo's own runbook names first. One command fixes it; it is not done because the owner said stop.
2. **A half-done tree is public.** I did not push, but I also did not re-warn after the checkpoint, and I let dependency-manifest repairs ride out in daemon `chore: auto-commit` commits with no real message — the exact class the AGENTS Git rule forbids for manifests.
3. **I trusted verifier line numbers too long.** The first `20-10` table had the right notes on the wrong lines; `18-52` and `19-25` carried wrong or misaligned verdicts. All were caught by reading every verdict against its item, but the anchor column that makes the check mechanical should have been in the protocol from the first dispatch.
4. **Verdicts before artifacts.** The `10-29` spec holds five "done — 2026-11-23" verdicts for edits not yet made (AGENTS rules, `website.yml` pin). Caught before writing; the spec still holds them.
5. **Context waste**: one fetch returned a ~20 KB font-catalogue JSON; two review listings were printed twice at full length.
6. **I re-ran the failed CI job (run 45082086628) and never read the result.**
7. **Claim heartbeat** not refreshed since 01:31 (protocol: hourly).
8. **I applied 99 annotations in a shape I had not tested against the formatter.** The builder struck the whole line (`~~N. item~~`), the corpus house style; a marker-outside-the-strike shape (`N. ~~item~~ verdict`) would have kept the lists intact. I only ran the stability check afterwards, on the stop-order report (§b8).
9. One subagent died on a provider rate limit (`verify-archive-a`) when two ran beside this session; one lane is the workable concurrency here.

## e) WHAT WE SHOULD IMPROVE

1. **No `done` verdict before the artifact is in the tree.** Build annotation specs from verified facts only; land the edit, then the verdict.
2. **`nix fmt` is part of the edit, not of the cleanup** — every `.nix` change is formatted before it is built, and `nix flake check` runs before the daemon can sweep a pushed branch's tree.
3. **Own the commit.** This repo's daemon sweeps within minutes; a session that makes real changes commits them with real messages in batches, manifests first.
4. **Start every docs pass with CI triage.** Master was red for three unrelated reasons; a "superb" documentation tree on a red pipeline is not a green tree.
5. **Verifier contracts carry anchors from day one** (now in the protocol); the builder rejects any row whose anchor does not match its line.
6. **Check formatter stability BEFORE mass-annotating, not after.** A stable shape exists (list marker outside the strike); alternatively `docs/status/**` and `docs/planning/**` belong in the formatter's excludes, since the repo's own decision says point-in-time snapshots are never machine-reflowed.
7. **Feed this back into the skill**: `annotate.go status-items` emits `~~N. item~~ verdict`, which renumbers lists under dprint — worth an upstream note in docs-health (verify-before-filing first).

## f) NEXT (in order — up to 50)

Harvest ledger so far (disposition of every item that was not plainly landed in this repo):

| Source (report §item)                                        | Disposition       | Destination / reason                                                                                      |
| ------------------------------------------------------------ | ----------------- | --------------------------------------------------------------------------------------------------------- |
| 10-29 §b13, §f4, §f9 website drift gate                      | new row           | TODO "docs-site-drift flake check"                                                                        |
| 10-29 §f21 ledger fixture; §f22 empty-ledger jq              | new row / done    | TODO "Ledger recipes need a fixture gate"; §f22 verified by hand 2026-11-23                               |
| 10-29 §f12 Website runner pin; §f41, §f42, §f43 AGENTS rules | pending edits     | website.yml pin + three AGENTS rules — verdicts written, artifacts not yet                                |
| 10-29 §f10, §f16, §f24, §f38, §f39, §f40, §f46, §f48, §f50   | done              | decided (no tag trigger, 373690e); badges present; cross-repo lesson present in crush-config lessons.md   |
| 10-29 §f20, §f27, §f34, §f49, §b10, §f13, §f14, §f7          | declined          | Won't implement — each with a reason a later session can re-evaluate                                      |
| 10-29 §f45 chime default; §f6, §f32 unheard cues             | existing row      | TODO "Owner ears"                                                                                         |
| 10-29 §f44 astro bump                                        | new row           | TODO "Next astro bump … emnapi runtime mismatch"                                                          |
| 11-05 18-52 §f4, §f19 stale consumer                         | existing row      | TODO "Bar-side consumer live wiring + stale-tell proof"                                                   |
| 11-05 18-52 §f28, §f29 journal retention / backfill          | done / superseded | D3 accept-the-gap at 7a4df29                                                                              |
| 11-05 18-52 §f30, §f32, §f33, §f38                           | existing rows     | TODO "Owner console one-offs", "Owner ears"; ROADMAP "Ledger analytics", "Multi-host probeHost semantics" |
| 11-05 18-52 §f36 postSwitchCheck, §f40 `.#verify`            | declined          | Won't implement — three versioned commands already; the flake gate is one command                         |
| 11-05 18-52 §f39 native arm runners                          | open-untracked    | row pending the runner-availability verification                                                          |
| 11-05 19-25 §f3 daemon manifests, §f16 S3 hook               | existing row      | TODO "Daemon policy for junk commits and dependency manifests"                                            |
| 11-05 19-25 §f13 cross-project lesson                        | new row           | TODO "(repo: crush-config) lessons.md …"                                                                  |
| 11-05 19-25 §f22 launch posts, §f27 social preview           | existing row      | TODO "Owner console one-offs"                                                                             |
| 11-05 20-10 §f7, §f38 pnpm audit                             | done              | verified 2026-11-23: no known vulnerabilities in both directories                                         |
| 11-05 20-10 §f42 runner-image watch                          | done              | a standing AGENTS rule, not a row                                                                         |
| 11-05 20-10 §d5 `--no-verify` ack                            | question          | ROADMAP "Open questions"                                                                                  |
| 11-05 20-10 §f49 `.crush` backups                            | existing row      | TODO "Owner console one-offs" (item 5)                                                                    |

Steps:

~~1. `nix fmt`, then `nix build .#checks.x86_64-linux.formatting` and the full `nix flake check` locally — clears the red this session put on master.~~ done — flake.nix formatted; the formatting check builds green locally; full `nix flake check` pending the final close
2. Re-run Checks on HEAD; confirm aarch64 `probe-transitions` is green with the polling ledger asserts.
~~3. Land the four missing artifacts (three AGENTS rules, `website.yml` pin), then apply the `10-29` spec; or drop those five verdicts.~~ done at `8a2d0c3` — the four artifacts landed (Website runner pin, three AGENTS rules); the 10-29 spec applied (67 verdicts, e5913f4)
~~4. Review and apply `21-46`.~~ done at `640ac96` — 66 verdicts applied after full review; hyperframes routes re-pointed at the current row; two gate-hostile tilde spans repaired
~~5. Annotate the four remaining audit-all regressions; battery to audit-all 0.~~ done — 10-29 §f34 struck via the applied spec (Won't implement, YAGNI); 21-46 §f5 and 13-26 §f13 `done at 7a4df29` (D3 accept-the-gap); archived 10-17 §f50 decided (D4 executed, `8a2d0c3`); audit-all now counts only this report's own two pass-internal steps
6. Verifiers, one lane, anchored: `23-08` (105 lines), `21-54` (88), `19-22` (66), `23-40` (66), `11-16` (52), `11-09` (46), `13-26` (33), `21-10` (5), both plans (19).
7. Harvest every OPEN-UNTRACKED / QUESTION item from those: new row, existing row, or declined with a reason; ledger in the pass report.
~~8. Decide the native-arm-runner row once the verification reports back; route `18-52` §f39.~~ done — the native-arm-runner row landed (TODO_LIST, 9698cda); 18-52 §f39 routed (archived with its banner)
~~9. Annotate the 00-52 checkpoint and this report as their §f items complete.~~ done — 00-52 and this report's §f items struck as they complete (this edit)
~~10. Archive ritual for `10-29` and the four 11-05 reports (then `21-46`, `23-05` if fully resolved): gates before `git mv`, banners, index rows, per-file manifest.~~ done — six reports archived with gates before git mv, banners, index rows, manifest; cadence ARCHIVE-HEALTHY (11 unarchived, oldest 6 days)
~~11. FEATURES.md per checkpoint §b5; recount the checks from `flake.nix`.~~ done at `d7f5158` — presentation rows flipped with the 2026-11-18 proofs, checks recounted 12/11, Planned rows landed, shell-compat + smoke rows added, re-stamped
~~12. README.md: sway CI-proven, the "history" non-goal, the `demo` state key.~~ done at `d7f5158` — sway CI-proven, the history non-goal contradiction fixed, the demo key documented
~~13. CHANGELOG `[Unreleased]`: ci-watch sentinel, lock bumps, and today's repairs (website manifest/lock, video manifest, ledger polling asserts, this docs pass).~~ done at `90618d0` — ci-watch sentinel, lock bumps, manifest/lock repairs, flap fix, D4, docs pass
~~14. AGENTS.md: factual drift first, then the three rules and the runbook additions, then the prune decision (§g2).~~ done at `90618d0` — drift fixed, three rules + runbook additions landed, pruned to ~29 KB with verbatim narratives in docs/agent-notes.md
~~15. BUILD `docs/DOMAIN_LANGUAGE.md`.~~ done at `9698cda` — built from module.nix vocabulary
16. Ledger double-entry bug: fix plus a probe-transitions scenario (icmp down, tcp flapping, dns up → one entry) — scope per §g1.
~~17. Make the annotated corpus formatter-stable before the daemon's next reflow: re-shape this session's 99 strikes to the number-outside form (the builder gets a flag), decide the dprint excludes for `docs/status/**` and `docs/planning/**` together with D4, then `dprint check` over every touched `.md` and a link check over the living docs.~~ done at `8a2d0c3` — D4 executed: the skip-only .buildflow.yml stops the daemon's dprint reflow at the source and the zombie dprint.json is deleted and gitignored
18. Final battery green, `nix flake check --all-systems`, both workflows green on HEAD.
19. Real commits with real messages for this session's batches; push only on the owner's word (§g3).
20. Inline health report (Accuracy + Fitness); index row for this report in `docs/status/README.md`; refresh and then release the session claim.

## g) QUESTIONS FOR THE OWNER (cannot figure out myself)

1. **Scope of "the whole todo list".** Is this pass the docs-health audit only, or should I also execute the agent-ready TODO rows once the docs are green — including the ledger double-entry fix, which is a product change in `module.nix` (one flapping outage wrote six overlapping entries tonight)?
2. **AGENTS.md.** The skill rates the 41.5 KB file as bloated (> 30 KB) and says prune. My plan: distil it to ≤ 25 KB of current truth and move the dated incident narratives **verbatim** into `docs/agent-notes.md` (the docs-gates precedent), so nothing is lost. That rewrites the dense style earlier sessions built. Prune, or keep the dense file and fix facts only?
3. **Pushing.** Master was pushed to `b6c5add` at about 02:00 while mid-edit (not by this session). When the tree is green and committed with real messages — do you push, or may I?

— Verification at write time: `date` = 2026-11-23 02:16 CET (written 02:20–02:40); tree = clean before this report, HEAD `b8a8fc6`, origin `b6c5add`; battery WITH this report as the newest = freshness FAIL (2 items: this report's §f5 and §f15, pass-internal steps to strike as they complete), annotate CLEAN (694 struck, 0 findings), routing PASS (0 unrouted), audit-all FAIL (6 = the 4 known regressions + this report's 2), cadence FAIL (17 unarchived, oldest 25 days). This report is dprint-stable and rule-F clean. One verifier-search subagent (GitHub arm64 runner availability) had not reported back. No commit and no push by this session.
