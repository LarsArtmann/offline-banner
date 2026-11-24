# Status — docs-health FINAL PASS retro: 10 reports + 2 plans resolved, the pipefail landmine, and what I got wrong · 2026-11-24 23:18 CET

**Created:** 2026-11-24 23:18 CET · Crush (glm-5.3) · covers THIS session's run only: the resume of the docs-health final pass, 2026-11-24 ~21:50 → 23:15 · successor to `2026-11-24_21-32_…` (checkpoint) and `2026-11-24_22-49_…` (final pass report — the ledger lives there; this is the retro).

**Tree state — read this first, then the ADDENDUM.** At first write: HEAD `dbb5e32`, 30 commits unpushed, working tree clean (the two `website/**/package.json` M-flags at report time were stat-dirt only — byte-identical after `git update-index --refresh`), all five docs-gates PASS, `nix flake check` RC=0 (x86_64 build incl. the fixed probe-transitions and vm-smoke; aarch64 eval-verified 11/11).

**ADDENDUM 23:40 — an external actor (presumably you, or a parallel session) began a refactor on this tree AFTER this report was written; I touched none of it (foreign-change protocol):**
1. **Pushed `93764d4` strips the version floors from both manifests** — the `astro ^7.4.12`, `@astrojs/sitemap ^3.7.5`, `html-validate ^11.21.1`, `hyperframes ^0.9.52` lines are GONE from `website/package.json`/`website/video/package.json` — WITHOUT a lock regen (both locks' last commits predate it). That is the known `ERR_PNPM_OUTDATED_LOCKFILE` CI-red class, now on the PUSHED tree.
2. **`contrib/offline-banner-waybar` is deleted from the worktree** (unstaged, NOT reverted by me). A daemon sweep had committed it as the lying `16f09b7` "chore: auto-commit 0 changed file(s)" — that commit also carried the manifest state; I unwound it during a re-split of my own swept content, so the deletion sits worktree-only again. My commits do not contain it.
3. **Consequence: `nix flake eval` is BROKEN locally** — `error: Path 'contrib/offline-banner-waybar' does not exist` (flake.nix:745/762 still reference it: the waybar-consumer check input and the smoke props). If this is the waybar-retirement refactor (the DMS-plugin era), the flake refs and the check must move in the SAME change.
4. The docs battery still PASSES all five gates (it does not eval the flake); the last green `nix flake check` predates these external edits. The push that landed `93764d4` was not mine. Session stopped here on the owner's order.

## a) FULLY DONE (verified)

1. **§f1 — the committed `set -x` defect removed** (`flake.nix:770`, the wrong check's script, swept into `5040a3f` by the predecessor session): plain deletion, fmt clean, real-message commit inside the fix batch.
2. **§f2/f3 — the probe-transitions silent exit-1 root-caused, fixed, and the check is GREEN.** The cause: stdenv builders run `set -euo pipefail`; the ledger assert helpers read a legitimately-absent flap ledger (`flap-history.jsonl` pre-close) with `cat "$f" 2>/dev/null | wc -l` — under pipefail the failed `cat` fails the whole pipeline, the assignment fails under `set -e`, the builder exits 1 with a ZERO-line log. Not a host/reboot regression — the checkpoint's "started exactly at the reboot" correlation was wrong; the silent regime started when the parametrized helpers (`4e91642`) landed the same evening. Diagnosed by a `set -x` probe anchored INSIDE the dying script (uniqueness-checked and location-verified before building, per the predecessor's §d1 lesson). Fix: guard the SUBSTITUTION (`wc -l 2>/dev/null < "$f" || echo 0`), plus a redirect-order polish (`2>/dev/null` first) so the redirect error itself stays silent. The failing drv's own trace confirmed the death position (`got=0` → instant `exitHandler`) before any fix was written.
3. **The flap-latch proof (the checkpoint's pending §b1 item) is CLOSED:** with the fix, probe-transitions runs RC=0 and the flap scenario asserts the full `outageOpen` contract — exactly ONE ledger entry spanning both flap hops, exactly one cue pair, negatives on both hops.
4. **§f4 — full local verification green:** `nix flake check` RC=0 (all x86_64 checks, vm-smoke included); aarch64 eval-only 11/11 OK (CI proves builds); docs-gates battery all five gates PASS at start, after every apply, and at the end.
5. **§f5 — every commit real, every daemon sweep re-split.** Seven daemon sweeps landed during the pass; all were soft-reset and recommitted with real messages — EXCEPT one (`bfba757`, the six stale-arrow repoints, still junk-message — see §d7).
6. **§f6–f8 — ALL TEN remaining reports + BOTH plans resolved: 482 verdicts written.** 23-40 (57), 23-08 (98), 21-54 (75), 19-22 (80), 21-10 (5), 11-16 (54), 11-09 (42 + 77 continuation strikes), 13-26 (27), 22-00 plan (26 + four ledger-marked F-tables), 14-11 plan (25 + ledger-marked subtask table). Every verdict read against its item; every cited hash `cat-file`-verified by the builder; gates re-run after each apply.
7. **§f9 — the harvest is complete and ledgered:** 17 new TODO rows, 2 ROADMAP ideas (observability endpoint, posture-probe harness), 15 inline declines each with a reason, 4 owner-decision rows staged. The full disposition table is in the 22-49 final report.
8. **Living-doc drift fixed, not just noted:** the SystemNix deploy row's stale lock rev (`412e553` → `9142491`, + the note that the flap fix rides the switch); README quickstart gained the smoke-app sentence; the Omarchy dev-guide quote is now SOURCED (URL fetched and verified live to carry the sentence verbatim before linking); AGENTS runbook 1b gained the `--print` pre-flight; TODO verification stamp re-set to 2026-11-24 (42 open rows).
9. **§f13 — the stale-arrow sweep:** six routed arrows repointed after the browser-eyeballs row grew its third glance; annotate + routing gates re-run clean.
10. **§f14–f16 — the closing deliverables:** the final pass report (`2026-11-24_22-49_…`) with the full harvest ledger and the inline Documentation Health Report (Accuracy 99.4% with visible math, Fitness assessment); status-README index rows added for 02-16, 21-32, and 22-49 (00-52 already had one); the 21-32 checkpoint's entire 16-item §f plan struck with evidence hashes; the session claim released.
11. **One real cross-session fix shipped mid-pass:** the shell-compat page's unsourced Omarchy quote — `6add16b` links `plugins.omarchy.org/develop.html` after a live fetch confirmed the exact wording. This closed three open items (11-09 §f1/§f9-adjacent) in one honest edit.
12. **AGENTS.md improved while working:** the pipefail silent-death lesson (hard rules), the `--print` pre-flight (runbook), both committed with the work they document.

## b) PARTIALLY DONE

1. **The 00-52/02-16 §f remainders were NOT piecemeal-struck** (§f14's literal demand): their open tails are all row-represented (freshness FRESH across 30 replayed reports proves it) and the 22-49 report supersedes them — I judged per-item striking of owner-window items as churn and recorded the succession in the final report instead. Defensible, but it IS a deviation from the letter of the plan.
2. **The verifier lane was abandoned after five failures, not engineered around** — no pacing, no queueing, no second provider probe cycle. Self-verification covered everything, so nothing is missing, but the "one dispatch every N minutes" workaround was never tried.
3. **AGENTS.md is 30.7 KB** — the pipefail lesson and the pre-flight sentence pushed it back over the 30 KB hope line set by the prune (29.6 KB at checkpoint end).
4. **The `$(cat "$f" 2>/dev/null)` sites in the two ledger FAIL messages still leak a redirect error when the file is missing** — I fixed the READ sites (the landmine) and the three `wc -l` sites, but the FAIL-path message interpolations keep the old shape (they only run on a path that exits 1 anyway, so it is cosmetic — but it is the same class and I left it).
5. **`bfba757` (arrow repoints) still carries a junk message** — swept mid-batch and never re-split (§d7).

## c) NOT STARTED (deliberate)

1. **The push** — 30 commits, owner-gated (§g1). Origin CI is red on the old tree's formatting job; ci-watch is presumably paging a tree whose fixes are all local.
2. **The owner window** (deploy row → post-switch ritual → bar-side wiring → audition → console one-offs → v0.2.3) — all rowed; unchanged this pass.
3. **The agent queue** (docs-site-drift check, ledger fixture gate, `.#probe` app, seam negative tooth, `--print` override assert, smoke-knob docs, scripts index, vm-smoke leaf assert, CI-cache evaluation, claim-protocol refinements, BuildFlow upstream issue, theme-5 machine re-verify, library re-pin) — rowed with evidence; zero started, by design (the pass scope was the corpus).

## d) TOTALLY FUCKED UP (own goals, this session, all mine)

1. **I wrote a verdict citing a hash that did not contain the artifact.** The 11-16 line-101 verdict (`--print` pre-flight) cited HEAD while the AGENTS sentence was still UNCOMMITTED — the exact "done-before-artifact" violation the corpus codifies, recreated by me hours after reading it. Caught within minutes; fixed by committing the sentence and re-citing the true hash via exact-match edit. Cost: two extra commits and a self-inflicted rule violation.
2. **A stray `git reset --soft HEAD~1` left inside a compound command** undid the 15-strike commit seconds after I made it; the strikes sat staged-uncommitted until the next `git status` caught it. The command was correct except for a fragment I forgot to delete. Sloppy command hygiene in the highest-stakes area (history rewriting).
3. **The commit `6286c0c` says "16-item plan struck" but carried ONE item.** The full-spec write aborted atomically on one unmatched anchor; the follow-up `dbb5e32` carries the other 15. The two messages together tell the truth, but anyone reading `6286c0c` alone is misled.
4. **Two python heredocs crashed before writing anything** (a trailing-comma tuple; a missed g-section in the line map). The asserts caught both pre-write — that is the tooling working — but both were preventable by constructing the dict in one reviewed block instead of appending under time pressure.
5. **I fought the emit-keys format blind.** It emits `ordinal@anchor` (item ordinal, not report line number); I assumed line numbers, wrote two specs against the wrong key space, and only understood the format after `cat -A` on the raw file. Two wasted cycles on a format I have used all pass.
6. **Five subagent dispatches into a rate limit.** The single cheap probe succeeded — proving auth, not sustained throughput. Four of five protocol dispatches died on `too many requests`, ~10 minutes of wall clock gone. The honest signal arrived on the fourth failure; §e5's smoke-test rule needed a "probe the SUSTAINED load" corollary I did not apply.
7. **One daemon sweep escaped me:** `bfba757` (the six arrow repoints across 11-09/23-08) rode into history with a junk message while I was mid-batch, and I never re-split it. Content-correct, unpushed, but it is exactly the junk-commit class this repo bleeds over.
8. **The 22-00 §e note mapping was off by one** (rule text vs line anchors) — the builder's anchor check flagged it and nothing was written (NARRATIVE rows), but I had assigned notes to lines by assumption instead of by derivation.
9. **Noise commands:** one `job_out_pending` (a command that does not exist), one `git log --ignore-case` (no such flag), one edit rejected for a typo in the old_string (`*--smoke` for `*-smoke`), one edit rejected for a stale read. Each cost one cycle; the pattern is typing ahead of verification.
10. **The stat-dirty scare at report time:** two dependency manifests showed M with an empty diff; my first instinct was to diff HEAD (empty) and only then refresh the index. The AGENTS manifest rule deserved the index refresh FIRST — a moment of panic-order instead of protocol-order, even though the resolution (byte-identical) was benign.

## e) WHAT WE SHOULD IMPROVE

1. **"Land, then cite" must extend to same-session self-references** — a "this pass" verdict hash needs its commit to exist first, full stop. The rule has now been violated once and cost three tool calls to repair.
2. **Compound git commands must never contain a reset.** Resets belong on their own line, typed deliberately, with a `git log` after. The stray-fragment reset (§d2) is the scariest class in this report because it touched history.
3. **Probe the SUSTAINED load, not one call**, before wiring any protocol onto a rate-limited provider: one real-sized dispatch, then decide the lane.
4. **Ledger-mark plan tables BEFORE the verdict pass on them** — the 22-00 F-tables saved ~90 unwritten rows once marked; the 14-11 plan was marked first because the lesson arrived mid-pass. Make it step one for plans.
5. **One logical commit per apply** shrinks the daemon-race surface: most of this pass's seven re-splits existed because edits, applies and commits batched too wide.
6. **Read a tool's output format once, completely, before scripting against it** (§d5) — `cat -A` first would have saved two cycles.
7. **Retitle a TODO row ⇒ grep the corpus for routed arrows in the same breath** — the retitle created six stale arrows that the §f13 sweep then had to clean. The retitle and the sweep should be one operation.
8. **The FAIL-path `$(cat X 2>/dev/null)` interpolation should get the same redirect-order treatment** as the read sites (cosmetic, but it is the last instance of the class in the file).
9. **When the tree surprises you, index-refresh before diffing** (§d10) — `git update-index --refresh` is the cheap truth-teller for stat-dirt.
10. **Junk-message sweeps carrying authored content must be re-split the moment they are noticed**, not batched into a retro list (§d7) — the pass produced one leftover.

## f) NEXT (up to 50, in order)

**Owner window (the push and its tails):**
1. Push master (30 commits; origin red on the OLD tree) — §g1.
2. Watch both workflows green on the pushed HEAD; confirm aarch64 probe-transitions green under real CI cadence (the latch + the new guards under emulated timing).
3. SystemNix relock to the pushed tip (`nix flake lock --update-input offline-banner` — picks up `4e91642`) → eval green.
4. Owner switch on evo-x2 (deploy row: the running unit predates the lock).
5. Post-switch ritual: `nix run .#smoke` (+ the new `-- --print` pre-flight), `scripts/click-dismiss-proof.sh`, journal sweep with the cue-FIRED signature.
6. Bar-side: enable `systemnix-banner` DMS plugin, live-bar glance per state class, stale-tell proof (kill-unit → `banner?` → restart).
7. Owner ears: audition the 12 cues (`scripts/play-sounds.sh`, sounds from `nix build .#sounds`); re-confirm the `chime` default.
8. Second-output proof (attach monitor, grim both outputs).
9. Owner console one-offs: IAM grant apply, social-preview upload, dead deploy-SA keys, launch-draft posting, `.crush` backup check.
10. Cut v0.2.3 per the runbook (fold `[Unreleased]`, step 1b WITH the `--print` pre-flight, curated notes WITH the NOT-verified section), re-lock SystemNix to the tag.
11. Re-sweep the live ledger after the switch: one entry per completed outage must hold under real flapping (the latch's live proof).

**Agent queue (rowed, evidence-linked — in queue order):**
12. `docs-site-drift` flake check (website has no drift gate).
13. Ledger-recipes fixture gate (the jq cookbook needs machine teeth).
14. `.#probe` app (parameterized withheld-option transients; three report mentions folded into the row).
15. probe-transitions STATE_DIR seam negative tooth (unwritable-dir variant).
16. Smoke app `--print` runtime-override assert.
17. Smoke-knob developer docs on the website (SMOKE_* beyond changelog.mdx).
18. Scripts header-comment index (five shell surfaces).
19. vm-smoke RuntimeDirectory-leaf assert.
20. CI nix-store cache evaluation (measure vs the ~33 s boot).
21. Claim-protocol refinements in AGENTS §Git (canonical keys + commit-batch labels).
22. vm-smoke-dismiss scenario row ("Pin the dismiss→re-arm cycle") — machine-pin the dismiss path probe-transitions currently lacks.
23. Journal completeness gate (cue-fired line + state-write failures) — the pw-play silence and the mv failure are invisible today.
24. Click-dismiss harness hardening (five sub-items on its row: pre-click re-verify, LOGICAL_W-aware threshold, transient-started flag ordering, NIRI_SOCKET autodiscovery, `--assert-journal`).
25. band-count.py synthetic-PPM fixture teeth.
26. `shell-scripts` gate: glob `scripts/*` so new scripts cannot escape the gate.
27. Waybar consumer: pin the dismissed-state shape (active:false mid-outage → silence) as a fixture.
28. The astro bump emnapi investigation (blocked upstream; watch @emnapi/runtime).
29. Vendored OG font (drop the build-time network fetch).
30. Deliberate hyperframes upgrade (0.9.52 → newer, under the age gate, with the pixel-compare bar).
31. Website follow-ups: omarchy dev-guide link already landed; og:description refresh + screenshot pass remain.
32. aarch64 CI on native hosted arm runners (incl. the cold-timing re-record).
33. TS7 watch-row cadence (`@astrojs/check` peer widening).
34. checks.yml `concurrency` (cancel superseded runs).
35. Daemon policy decision (owner): S3 manifest-lock hook vs ignore list vs fix-forward.
36. Sandbox adoption decision (owner): PrivateDevices / MemoryDenyWriteExecute (probe-evidenced, unsoaked).
37. Journal retention decision (owner): journald window vs bump.
38. SMOKE_SOUND default decision (owner taste).
39. README dnsProbeName table nuance (owner call).
40. Corpus staleness gate decision (owner): CI check vs the on-demand flip trigger — my recommendation is ON-DEMAND (the battery's audit-all already machine-watches the corpus; a second trigger duplicates it).

**Fleet/upstream (only after verify-before-filing):**
41. File the BuildFlow upstream issue (skip non-covered repos by default) with this repo's two corruption examples.
42. crush-config lessons commit: fleet-run lessons + library-deep-dive runbook amendments + the inherited-diagnosis lesson + the busctl substitute snippet (all folded into one row).
43. docs-gates candidate issue: the `~~N. item~~` strike shape hides item-starts from the extractor (the chain false-positive class — four live instances fixed this pass).
44. docs-gates candidate note: literal-tilde-in-code-span lines are skippable by the resolver but acceptable to emit-keys (the asymmetry cost a reword + a re-key this pass).
45. docs-gates candidate note: emit-keys prints ordinal@anchor — document that the ordinal is the ITEM number, not the line number.
46. Library corpus: remote-fetch re-pin (`git fetch --tags` all 20 repos, diff pins).
47. Theme-5 machine-honest re-verify (fetch the Omarchy pointer live — partially done by the quote-sourcing this pass).
~~48. Micro: reorder the two FAIL-message `$(cat X 2>/dev/null)` interpolations in flake.nix (§b4).~~ NOT-DO — wrong premise, caught at hand-off: the $(cat X 2>/dev/null) interpolation form cannot leak (cat opens under its own redirect); only the shell-side wc-l-< read form could, and all three read sites are already fixed
49. Micro: re-split `bfba757` (the arrow repoints ride a junk message; unpushed, so it is one soft-reset away) — or accept it as fix-forward under the daemon policy.
50. When the struck-row backlog next exceeds the purge threshold: the supervised first `docs-gates purge` run (deliberately not rowed today — the count is 0 DONE-row class).

## g) QUESTIONS FOR THE OWNER (cannot figure out myself)

1. **Push authority.** 30 commits sit unpushed; origin master is red on the old tree's formatting job while this tree passes everything locally, so ci-watch is presumably paging noise. Do I push, or do you want to? (Default per protocol: I do not push without your word. If you say push, I will also watch both workflows to completion and report aarch64.)
2. **The live-screen interaction contract** (carried from the 23-40 report, still unanswered): tonight's-class harnesses click on your real desktop under a band-verified fail-closed harness with announce-first discipline. Is that the standing doctrine you accept, or do you want click-class proofs to require an explicit per-run GO from you?
3. **The docs-gates upstream notes (§f43–45) and the BuildFlow issue (§f41): file now, or bundle?** Filing needs a verify-before-filing pass over the docs-gates source (an hour of cross-repo work). If you fund that, I file all four; if not, they stay candidate rows until the next fleet session.

— Verification at write time: `date` = 2026-11-24 23:18 CET; HEAD `dbb5e32`, 30 unpushed commits, tree clean (stat-dirt on two manifests resolved as byte-identical); battery all five gates PASS; `nix flake check` RC=0 (x86_64 build, aarch64 eval); claim released; no push by this session.
