# Status — TODO-List Execution + the Two-Session Dance (2026-11-18 21:54 CET)

**Scope line — VERIFIED here:** the merged working tree's 11 flake checks each built green explicitly (`nix build .#checks.x86_64-linux.<name>` per name, 21:40-ish: module-contract, unit-verify, docs-drift, shell-content, probe-transitions, render-smoke, shell-scripts, waybar-consumer, smoke-script, leg-contract, formatting) plus `nix build .#vm-smoke` exit 0; my `T56` fix live-proven via two real sandboxed transients (`ob-probe-pdev`/`ob-probe-mdwe`, journals 20:15:29–20:16:08, state file `/run/user/1000/offline-banner-smoke/state` valid JSON, mtime 20:16:08); ci-watch dispatch run **44378069140** completed success (read back via `gh run list`) + scheduled greens 44377152758/44371378637 + red path proven by executing the workflow's script body under a local `gh` shim (exit 1, `::error::` annotation); probe verdicts from `journalctl --user -u ob-probe-pdev/-mdwe`; index link coverage verified both directions (22 hrefs / 22 unique / 22 files, zero dead, zero unlinked). **NOT verified here:** anything on GitHub — nothing was pushed, so branch protection and both CI workflows have NOT judged tonight's tree; the merged commits of the parallel session (1c94cb7, cbeb31b, dc571a3, ee96b8d, 8aa91d4, ea5b0af, 4546279, cb51ea3, bc1bc2f) were reviewed only where this session read their diffs; SystemNix is untouched; the red path inside the REAL ci-watch workflow on GitHub has never executed (local shim only); the demo strips my probes rendered appeared on the owner's real monitor without announcement (silent, ~12 s each).

**Context that shapes everything below:** a second agent session worked the SAME TODO rows concurrently all evening (its first edit landed 20:07:28, nine seconds after my read of the same file). This session detected it on the first refused edit, created the proposed claim file (`docs/status/.session-claim`, gitignored), divided scope, and the two sessions composed cleanly — no stomps, verified. Several "done" items below are joint.

---

## a) FULLY DONE

1. **State-file writer hardened to pid-unique stage temps (T56)** — `"printf '%s' \"$2\" > \"$1.$$.tmp\" && mv -f \"$1.$$.tmp\" \"$1\""` in module.nix `emitState()` (go-atomic-write's stage-collision doctrine as spec). Evidence: live transient wrote a complete state file through the new stage (mtime 20:16:08); probe-transitions + vm-smoke green on the merged tree. Committed — unfortunately as daemon junk `2e89acb` (see d3).
2. **ci-watch actually verified (T90)** — `workflow_dispatch` run 44378069140 → success; green path doubly proven by scheduled runs 44371378637 + 44377152758; red path proven locally (script body + `gh` shim returning a failed Website run → exit 1 with the `::error::` line). TODO row 90 closed with run ids.
3. **Both remaining withheld sandbox options probed (T54 evidence leg)** — `PrivateDevices=true`: quickshell survives (QML loads, `banner state=shown`, stable 12+ s; GPU denied → MESA-EGL/ZINK software-fallback warnings). `MemoryDenyWriteExecute=true`: survives (QML loads, state=shown, stable 12+ s). Verdicts recorded in TODO_LIST row 54 + AGENTS sandbox-posture paragraph; posture UNCHANGED — both are adoption candidates pending a 24/7 soak + owner call.
4. **Demo-cue chime question closed (T91)** — journal re-sweep of the 12:46 smoke unit: `banner state=shown` at 12:46:43, NO sound line = quiet success (the cue journals only pw-play's non-empty stderr; a failure would have printed since ab56830); owner's audible report completes it. The unannounced-chime class is dead anyway (smoke demos now silent by default).
5. **Stale TODO rows closed with evidence** — row 15 (evening-flap: the gen-995 sweep — 1502 silent degraded vs 13 genuine offline — IS the evening verdict), row 25 (no tag-trigger CI: decision already recorded in AGENTS), rows 16/22 retagged `[blocked:user]` honestly, row 87 gained tonight's live protocol data point, row 34's render leg was closed by the parallel session.
6. **docs/review corpus refreshed** — go-atomic-write.md: fresh recount under a pinned methodology (`!docs/review/**` + `!docs/status/**`, living files: go-atomic-write 4, cmdguard 1, templ-components 1, go-cqrs-lite 1 — 0 dependency surface), the unique-temp recommendation marked **IMPLEMENTED 2026-11-18**, §7 verify block updated; index.html honesty note rewritten with the fresh counts + note (4) resolving the "21 vs 22" artifact (committed index verified 22/22 both directions — the stale count was taken against a mid-session working tree).
7. **CHANGELOG [Unreleased] gained two Fixed entries** — smoke-transient isolation + silent-by-default sound; pid-unique stage temp. Both swept into `ee96b8d` (mixed-session commit, see d3).
8. **Claim-file protocol exercised live** — `docs/status/.session-claim` created + heartbeated + finalized; it successfully scoped two sessions onto disjoint rows all evening; row 87 records the data point (works for scoping; daemon-side awareness still missing).
9. **Merged-tree verification** — after both sessions' commits settled: every one of the 11 checks built green explicitly + vm-smoke green; `nix fmt` clean throughout.
10. **Parallel session's work verified and co-closed** — rows 88 (smoke isolation: suffixed `*-smoke` dirs, `OFFLINE_BANNER_STATE_DIR` seam, `RuntimeDirectoryPreserve=true` for the shared quickshell dir, sound props split behind `OFFLINE_BANNER_SMOKE_SOUND=1`, smoke-script pins every shape both directions) and 89 (AGENTS Release step 1b) closed in TODO_LIST with their commit ids; their AGENTS hazard note also surfaced a THIRD latent smoke bug they fixed (props read a nonexistent `serviceConfig.Environment` attrset — the transient had silently run on QML defaults).

## b) PARTIALLY DONE

1. **TODO_LIST sweep** — 10 rows closed/retagged tonight, but the list still carries 9 open rows, all genuinely owner-gated or watch-class: 16 (owner enables DMS plugin + live-bar look), 22 (owner ears on 12 cues), 34 (three live legs: reboot auto-start, second output, click-to-dismiss — the parallel session is landing recipes), 79 (owner-ears leg on the next natural outage), 80 (D1 vm-smoke promotion decision), 81 (D3 ledger backfill decision), 82 (stale-tell M08 proof after the plugin deploys), 83 (TS7 upstream watch), 87 (daemon-side claim adoption), 92 (v0.2.2 tag+push). Blocker for all: owner or external events. Effort: each S–M once unblocked.
2. **v0.2.2 release prep** — the parallel session landed docs prep (`8aa91d4`); the runbook (fold CHANGELOG, website changelog page sync, both-workflows-green gate, step 1b app execution, tag + curated release, tag-source verify) is written but unexecuted. Blocker: tag+push is owner-gated. Effort: M (mostly mechanical).
3. **Claim-file protocol** — scoping works; the daemon still sweeps cross-session files into shared chore commits (tonight produced at least three mixed commits). The missing piece is daemon-side claim awareness + an rc-guard auto-create. Blocker: owner adoption (fleet daemon config). Effort: M.
4. **Sandbox posture (row 54)** — evidence leg complete, posture decision leg open: adopting `PrivateDevices`/`MDWE` needs a 24/7 soak and flips the posture (always-software rendering; QML JIT loss under MDWE). Blocker: owner tradeoff call. Effort: S to decide, L to soak properly.
5. **CI verdict on tonight's tree** — all green locally; nothing pushed, so CI has seen none of it. Blocker: push is owner-gated by harness rules. Effort: S.

## c) NOT STARTED

1. **The three §g questions from the 19:22 fleet-review status report** — still unanswered (no-Go posture permanence; daemon squash policy; corpus staleness gate). Not started because they are owner questions, not tasks.
2. **D1** — vm-smoke into `checks` (blocking) or advisory wiring. Built, green, negative-proven; parked since 2026-11-05 awaiting the owner call (a tcg VM check slows every CI run by minutes).
3. **D3** — lost-ledger-window backfill (accept the gap vs reconstruct from router logs with `backfilled:true`). Decision row, never started.
4. **D4** — BuildFlow `.buildflow.yml` adoption (the dprint/global.out.css zombie's permanent kill). Owner-gated, never started.
5. **PrivateDevices/MDWE adoption path** — soak harness, contract updates, `systemd-analyze security` re-rating, docs. Probes done; adoption work not started.
6. **Post-reboot checklist / second-output test / wlrctl click-dismiss recon (row 34 legs)** — the parallel session's recipes are "landing in this plan" per its row text; nothing exists yet that this session saw.
7. **Cue-fired journal line** — a one-line QML log when a cue FIRES (not just on pw-play stderr) would make future row-91-class audits ear-free. Idea only.
8. **`.#probe` app** — parameterized withheld-option transient harness (one command per option, gated) so posture probes stop being hand-built systemd-run lines. Idea only.
9. **index-render screenshot regeneration** — the honesty text changed after `index-render-2026-11-18.png` was captured; the png is stale by one paragraph. Cosmetic.
10. **README/FEATURES smoke-isolation mention** — the smoke app's new isolation/silence knobs are dev-facing; neither doc mentions them. Probably belongs in a contributing/dev-docs note, not the sales page — undecided.

## d) TOTALLY FUCKED UP

1. **Three real fixes are entombed under junk commit messages, and one of them is unre-splittable.** My T56 module.nix fix landed inside daemon chore `2e89acb`, sandwiched BETWEEN the parallel session's commits — re-splitting it means rebasing across commits I did not author, which the parallel-session protocol forbids. The history now permanently reads `chore: auto-commit 1 changed file(s)` where it should read `fix: pid-unique state-file stage temp`. Same class: `ee96b8d` mixes the parallel session's AGENTS+CHANGELOG work with MY eight TODO_LIST closures, and `cb51ea3` mixed five files across both sessions. Severity: history readability + the AGENTS "daemon must never own meaningful changes" discipline eroded; no functional damage (everything verified green). Root cause: the daemon commits on a timer with a heuristic message and zero claim awareness. Mitigation: none retroactive; forward fix is row 87's daemon-side adoption.
2. **This session edited shared files while another session was live, and only the edit tool's mtime guard prevented stomps.** My first module.nix edit was refused (file modified 9 s after read); my AGENTS.md edit was refused twice (their edits at 20:21:04 and 20:23:51). I had checked `git status` — which is BLIND to in-flight work — and concluded the tree was quiet. Root cause: I planned edits off repo state instead of session-state; the claim file was created only AFTER the first collision instead of at session start. No data was lost (verified: worktree TODO_LIST converged to a superset of both sessions' edits), but the margin was luck + tooling, not process.
3. **Two full verification batteries were wasted racing the other session's mid-refactor tree.** My first `nix flake check` died on their half-landed smoke-script refactor (gate expected `done < "$props_file"`, their rewrite had moved to `read_props()`); they fixed their own gate minutes later. My next battery then hit their red seam scenario (`seam state never went active in the redirected dir` — their harness scenario didn't arm demo mode). Neither failure was mine, but I burned cycles exonerating my change (diffed their commits, checked my QML string for Nix-escaping traps on `$$`) before their fixes landed. Severity: time, plus a real misattribution risk — a careless session would have "fixed" their in-flight work.
4. **Row 54's checkbox was missed in my first closure pass** — I updated the body with the probe verdicts but left `- [ ]`; caught only in the final open-rows audit. Small, but it is exactly the "closed with evidence" discipline the list lives on.
5. **My probes rendered demo strips on the owner's real monitor, twice, unannounced** (~12 s each, 20:15 and 20:16). Sound was proven silent (the fix working), and the F62-precedent says the probe crashes only the demo surface — but the owner was not told in advance. Severity: cosmetic trust issue. Mitigation: none needed retroactively; forward: announce live-session probes in the session's first message.
6. **The evidence-grep counts in the docs/review corpus rotted within hours of being written** — the report said 2, the index said 3, tonight's recount says 4 (my own session's edits added mentions). Root cause: unpinned methodology (status snapshots included/excluded ad hoc). Now pinned (living-files globs), but the counts are still a snapshot that any future doc edit re-stales.

## e) WHAT WE SHOULD IMPROVE

1. **Session-start ritual: claim file FIRST, then mtime-pulse, then plan.** `git status` cannot see another session's in-flight edits; a 30-second `stat` pulse on the files I intend to touch (or `ps` for crush/agent processes) would have predicted every collision tonight. Concrete: add to AGENTS parallel-session protocol — before editing, `stat` target files twice ~60 s apart; changing mtime = another session is live → claim + divide.
2. **Targeted edits compose; full-file writes stomp.** Tonight's clean merge happened because BOTH sessions used find/replace-style edits on current content. Make it a rule in the protocol: never `write` (full-file) a shared living doc while a claim file is fresh; always `edit`/`multiedit` with exact anchors.
3. **Daemon claim-awareness is the single highest-leverage process fix** (row 87): skip the auto-commit while any `docs/status/.session-claim` heartbeat is fresh (<2 h), or at minimum include a session tag in the message. Tonight produced three mixed-session chore commits that each required forensic diffing to attribute.
4. **When a check goes red, attribute before touching.** Tonight's two reds were both the other session's in-flight work. Rule: `git log --oneline -5` + re-run the single check + read its diff before assuming your change caused it. (I eventually did this; doing it FIRST saves a battery run.)
5. **Pin counting methodologies with their globs, not just numbers.** "8 mentions" rotted in hours; "4 living-file mentions under `!docs/review/** !docs/status/**`, recount date" survives. Applied tonight in go-atomic-write.md §3/§7 — replicate in the other 21 reports' verify blocks when they next refresh.
6. **Version the posture-probe recipe as a flake app (`.#probe --option=PrivateDevices`).** Tonight's probes were hand-built 30-property systemd-run lines (twice). A parameterized app + a `posture-probe` gate would make the owner-supervised soak a one-liner and prevent drift from the rendered sandbox.
7. **Close rows by checkbox AND body.** The TODO lifecycle is the project's memory; a body-updated-but-open row reads as pending forever. (Caught tonight; make it a checklist habit.)
8. **Local green ≠ CI green.** Nothing pushed tonight means branch protection never judged the tree; the release runbook's "both workflows green on the HEAD commit" gate cannot be satisfied until a push. Plan pushes (or explicitly note the gap) at session end, not just local verification.
9. **Announce live-session effects up front.** Probes/demo transients render on the owner's screen. One sentence at session start ("I will flash demo strips twice while probing") costs nothing.
10. **Status-snapshot §g questions should be re-asked until answered** — the 19:22 report's three questions aged six hours with zero movement; they gate real decisions (notably the corpus staleness gate, which would have automated tonight's refresh question).

## f) Up to 50 things to get done next

Routing legend: `[row N]` = TODO_LIST row, `[road]` = ROADMAP fuel, `[new]` = surfaced tonight. Impact/Critical-High-Medium-Low, Effort/S-M-L.

1. **Push tonight's commits and let CI judge the merged tree** (both workflows on the tip). Impact Critical, Effort S, Category Quality. `[new]` — owner-gated push.
2. **Cut v0.2.2 per the runbook** (fold CHANGELOG, website changelog page, both-green gate, execute step 1b app-first, tag, curated release, tag-source verify). Impact High, Effort M. `[row 92]` — docs prep already landed (`8aa91d4`).
3. **Run AGENTS Release step 1b explicitly for v0.2.2** (`OFFLINE_BANNER_SMOKE_DEMO=1 nix run .#smoke` on the exact tag tree, journal receipt, stop). Impact High, Effort S. `[row 89]`.
4. **Answer the 19:22 fleet-review §g questions** (no-Go posture, daemon squash policy, staleness gate). Impact Medium, Effort S. `[new]` — owner-only.
5. **Decide PrivateDevices adoption** after a 24/7 soak on a live unit (software-rendering tradeoff). Impact High, Effort L. `[row 54 follow-up]`.
6. **Decide MemoryDenyWriteExecute adoption** (JIT-loss tradeoff; measure QML init delta). Impact High, Effort L. `[row 54 follow-up]`.
7. **If either option is adopted:** update module-contract sandbox line list + re-rate `systemd-analyze security` + docs + AGENTS posture + CHANGELOG. Impact High, Effort M. `[new]`.
8. **Build `.#probe`**: parameterized withheld-option transient app + gate. Impact Medium, Effort M. `[new]`.
9. **D1 decision: promote vm-smoke into checks.x86_64-linux (blocking) or wire advisory**, with a measured CI-minutes delta. Impact High, Effort M. `[row 80]`.
10. **D3 decision: lost-ledger-window backfill** (accept vs reconstruct with `backfilled:true`). Impact Medium, Effort S to decide. `[row 81]`.
11. **Owner: enable `systemnix-banner` DMS plugin + live-bar look** after the next SystemNix switch. Impact Medium, Effort S. `[row 16]`.
12. **Owner: audition all 12 sound cues** via `scripts/play-sounds.sh` + tune. Impact Medium, Effort M. `[row 22]`.
13. **Owner: ears on the next natural outage** (the last audibility leg). Impact Low, Effort S. `[row 79]`.
14. **Row 34 leg: reboot auto-start verification** (graphical-session.target post-reboot checklist). Impact Medium, Effort M. `[row 34]`.
15. **Row 34 leg: multi-monitor proof** (second output). Impact Low, Effort S. `[row 34]`.
16. **Row 34 leg: machine-verified click-to-dismiss** (wlrctl/virtual-pointer harness). Impact Medium, Effort L. `[row 34]`.
17. **Daemon claim-awareness**: skip auto-commit while a fresh claim file exists. Impact High, Effort M. `[row 87]`.
18. **rc-guard snippet**: auto-create the claim file at session start. Impact Medium, Effort S. `[row 87]`.
19. **Record tonight's protocol lessons in AGENTS** (mtime-pulse before edit; targeted-edits-compose/full-file-writes-stomp). Impact Medium, Effort S. `[new]`.
20. **Decide the junk-commit policy**: are mixed-session `chore:` entombments acceptable below a pushed tip, or must sessions re-split at landing time (and may they rebase across foreign commits)? Impact Medium, Effort S. `[new]` — owner-only.
21. **Verify their seam scenario's negative tooth**: does probe-transitions now FAIL if the seam dir is unwritable or demo isn't armed (the class their bug represented)? Impact Medium, Effort S. `[new]`.
22. **Smoke-script: confirm the sound gate's negative direction is pinned** (props WITH sound when opt-in, without by default — they assert both; verify the opt-in assert actually runs). Impact Low, Effort S. `[new]`.
23. **Add a cue-fired journal line** (`cue fired event=show`) so audits are ear-free. Impact Medium, Effort S. `[new]` → improves rows 91/79 forever.
24. **Regenerate the index-render screenshot** (honesty text moved after capture). Impact Low, Effort S. `[new]`.
25. **Website: fold the v0.2.2 changelog section + smoke-isolation/dns-validation notes into changelog.mdx** before the tag. Impact High (release gate), Effort S. `[row 92]`.
26. **Website: document the dns validation behavior change prominently** (hosts with blocked probe names will now see real outages) — release-notes callout per row 92's own note. Impact High, Effort S. `[row 92]`.
27. **Website/developer docs: smoke app knobs** (`OFFLINE_BANNER_SMOKE_SOUND`, isolation guarantee) in a contributing/dev note, not the sales page. Impact Low, Effort S. `[new]`.
28. **FEATURES.md: smoke-isolation + seam sentence** (keep the inventory honest). Impact Low, Effort S. `[new]`.
29. **SystemNix consumers row update after the next switch** (gen-99x boots the seam QML + pid-unique temp under the real sandbox). Impact Medium, Effort S. `[road]`.
30. **Post-switch: one deliberate or natural outage to re-prove the ledger through the live unit** (post-seam QML). Impact Medium, Effort S. `[road]`.
31. **Row 82: stale-tell M08 live proof** (kill the unit, `banner?` within one heartbeat) once the DMS plugin deploys. Impact Medium, Effort S. `[row 82]`.
32. **Re-triage dependabot alerts** after tonight's merges (was 30 open at the morning triage; undici cluster should have closed with the hyperframes merge). Impact Medium, Effort S. `[row 76]`.
33. **Watch picomatch ReDoS for 4.0.8 upstream** (alert self-resolves; scheduled updater retries). Impact Low, Effort S. `[row 76]`.
34. **Apply the staged IAM grant in Terraform** (`serviceusage.serviceUsageViewer` — still owner-side only). Impact Medium, Effort S. `[row 24]`.
35. **Owner: upload the social preview** in repo settings (no API). Impact Low, Effort S. `[row 75]`.
36. **Owner: disable dead deploy-SA keys in GCP** (11 enabled, several unattributed). Impact Medium, Effort S. `[row 75]`.
37. **Owner: post the launch drafts** (Discourse + r/NixOS). Impact Medium, Effort S. `[row 73]`.
38. **TS7 watch**: check `@astrojs/check` peer widening monthly; bump when it opens. Impact Low, Effort S. `[row 83]`.
39. **Re-verify the Checks workflow on the next GitHub runner-image announcement** (ubuntu-24.04 pin doctrine). Impact Medium, Effort S. `[AGENTS CI]`.
40. **Keep workflow-lint tool pins in lockstep with flake.lock moves** (zizmor build-breakage doctrine; next nixpkgs bump). Impact Medium, Effort S. `[AGENTS CI]`.
41. **docs-health HARVEST this report's f-list** into TODO_LIST/ROADMAP (the actionable ones above mostly already have rows; the [new]/[road] ones don't). Impact Medium, Effort M. `[skill loop]`.
42. **Add this report's row to docs/status/README.md**. Impact Low, Effort S. `[new]` — DONE AT SUBMISSION: the README row landed in the same sweep as the report (c6a6cfe, docs/status/README.md +1).
43. **Brutal-self-review of the two-session evening** (ghost systems, split brains across the merged commits). Impact Medium, Effort M. `[new]` — owner call.
44. **Pin the mention-count methodology across the other 21 reports' verify blocks** (living-file globs + recount date). Impact Low, Effort M. `[new]`.
45. **Ledger writer audit**: confirm append-only `>>` is safe under the overlap class T56 fixed (no stage file, but two appenders can interleave lines — likely fine for JSONL, decide explicitly). Impact Medium, Effort S. `[new]`.
46. **ROADMAP: observability endpoint** (optional Prometheus/socket stats off the state file). Impact Low, Effort L. `[road]`.
47. **ROADMAP: fleet-reusable posture-probe harness** (generalize `.#probe` beyond this repo). Impact Low, Effort L. `[road]`.
48. **Sanity-verify `--print` includes runtime overrides** (`SMOKE_DEMO`/`SMOKE_SOUND`/probe-host args appear in printed output — args are built before the print branch, but assert it in the check). Impact Low, Effort S. `[new]`.
49. **Audit remaining `writeTextDir` QML for other single-writer assumptions** (anything else keyed to instance lifetime — quickshell log dirs, cache eviction). Impact Low, Effort S. `[new]`.
50. **Next session: mtime-pulse + claim file BEFORE the first edit** — tonight's lesson institutionalized. Impact High, Effort S. `[new]` → feeds e1.

## g) Three questions I cannot answer myself

1. **Sandbox posture:** with both `PrivateDevices` and `MemoryDenyWriteExecute` now demo-proven survivable — do you want the hardening path (24/7 soak, then adopt whichever survives, accepting always-software rendering and the QML JIT loss), or is the 5.8 MEDIUM rating permanently accepted as the price of a working banner? This gates whether rows 54's follow-ups become real work and whether the module-contract sandbox list changes again.
2. **Commit-history policy:** tonight three real fixes landed entombed inside mixed-session `chore: auto-commit` commits (T56 sits in `2e89acb`, unre-splittable without rebasing across the other session's commits, which the protocol forbids). Is entombed-but-verified acceptable history to you, or should future sessions re-split at landing time even when that means touching foreign unpushed commits (which would need a protocol change)?
3. **Release authority for v0.2.2:** should an agent session execute the full runbook end-to-end (push master → CI green → step 1b app execution → fold + tag + curated `gh release create` + tag-source verify) and hand you a finished release, or do tag+push stay strictly yours? Everything up to the push is verified-ready locally.

---

*Point-in-time snapshot. Verified-locally-only; nothing pushed. Waiting for instructions.*
