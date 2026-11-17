# Status Report — docs-health full AUDIT on offline-banner

**Generated:** 2026-10-16 23:58 CEST · **Scope:** this session only — the "execute docs-health PROEPRLY, all six docs SUPERB" run. No unrelated research performed, per instruction.
**HEAD:** `fff0b61` (all session work auto-committed by the daemon; tree clean at report time) · **Gate:** `nix fmt` clean + `nix flake check` → `all checks passed!` (x86_64-linux; aarch64 leg omitted by the local runner — known decision row).

**Format note:** status-report skill is HTML-canonical; you explicitly demanded `.md` at this path — same one-off override as the 23-28 report, flagged, not propagated into the skill.

**Skills loaded & applied this session:** `docs-health` (full AUDIT: BUILD + HARVEST + VERIFY + report; all references loaded), `status-report` (this file; section-quality guide applied). brutal-self-review folded into §d/§e per your single-file instruction.

---

## a) FULLY DONE

| #  | What                                                                                                                                                                                                                                                                                                                                                                                                  | Evidence                                              | Files                               |
| -- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- | ----------------------------------- |
| ~~a1~~ | ~~**Full docs-health AUDIT executed** — every skill reference loaded, every project file read end-to-end (module.nix all 354 lines, flake.nix, checks.yml, dprint.json, .gitignore, all six docs, the 23-28 report)~~ done (docs-health pass 2026-11-17) | ~~Findings table in the inline health report; this file~~ | ~~—~~ |
| ~~a2~~ | ~~**External-claims leg verified live** — remote exists (public, pushed 2026-10-16T21:22Z via `gh`); CI red root cause re-verified (installer pin → GitHub API 422); checkout pin valid (v7.0.1 resolves); repo topics unset; SystemNix sibling evidence paths, option-parity (`package`/`layerNamespace` genuinely new vs the SystemNix original), and the wifi-failover iface-list twin all confirmed~~ done — re-verified across every later audit | ~~`gh api` outputs in session; ../SystemNix greps~~ | ~~—~~ |
| ~~a3~~ | ~~**FEATURES.md built** — evidence-cited inventory; runtime rows honestly `PARTIALLY_FUNCTIONAL` (origin-proven, unverified since extraction+sandbox), eval rows `FULLY_FUNCTIONAL`, CI honestly `BROKEN`; audit-stamped~~ done at `fff0b61` | ~~Committed by daemon~~ | ~~FEATURES.md~~ |
| ~~a4~~ | ~~**ROADMAP.md built** — 3 themes (probe expressiveness, operational smoothness, verification depth) + doctrine-derived non-goals; zero TODO overlap~~ done at `fff0b61` | ~~Committed by daemon~~ | ~~ROADMAP.md~~ |
| ~~a5~~ | ~~**TODO_LIST.md rebuilt via full HARVEST** — the 23-28 report's §f (50 items, explicitly "HARVEST-ready") + 10 existing rows → 21 deduped rows, every row carrying `file:line` + report sources; done push-row deleted; misrouted tunables row routed to ROADMAP; all 50 §f items dispositioned in a ledger~~ done — TODO rebuilt; maintained since (this pass re-verified it) | ~~TODO_LIST.md; ledger in the inline health report~~ | ~~TODO_LIST.md~~ |
| ~~a6~~ | ~~**README fixed ×4** — consumer `nixpkgs.follows` quickstart line, hardened-unit bullet, restart note on env tuning, compositor claim softened to "proven on niri" (was an unverified overclaim)~~ done at `fff0b61` | ~~Committed by daemon~~ | ~~README.md~~ |
| ~~a7~~ | ~~**AGENTS.md verified + 2 surgical edits** — disk was fresher than the session snapshot (prior session had already fixed the remote claim; I claimed nothing for it); added dprint-split-brain acknowledgment + cutover smoke-test gate. Still 2.5 KB lean~~ done at `fff0b61` | ~~Committed by daemon~~ | ~~AGENTS.md~~ |
| ~~a8~~ | ~~**CHANGELOG `[Unreleased]` appended** (append-only respected) + **docs/status/README.md index created**~~ done at `fff0b61` | ~~Committed by daemon~~ | ~~CHANGELOG.md, docs/status/README.md~~ |
| ~~a9~~ | ~~**Quality gate green twice over** — `nix fmt` 0 changed; `nix flake check` all checks passed (formatting + module-contract)~~ done — gate green at every later session | ~~Session tool output~~ | ~~—~~ |

**Scores (as-found, per the docs-health math discipline):** Accuracy 8.25/10 · Fitness 6.5/10. First audit — no baseline, none invented.

## b) PARTIALLY DONE

| #  | Item                                                 | Works                                                       | Open                                                                                                                                                                                                         | Blocker                                    | Effort |
| -- | ---------------------------------------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------ | ------ |
| ~~b1~~ | ~~**Docs now exist, but nothing enforces their truth**~~ done — shipped as the docs-drift flake check (2026-10-17, T19) | ~~Six living docs + index, all cross-consistent at write time~~ | ~~No standing drift gate — the accuracy of FEATURES/TODO claims decays by hand from tonight on; markdown files additionally sit under NO formatter gate at all (treefmt covers `.nix` only; dprint.json inert)~~ | ~~dprint/BuildFlow decision row in TODO_LIST~~ | ~~S–M~~ |
| ~~b2~~ | ~~**Status index**~~ done — maintained per report through 2026-11-05; two late rows backfilled 2026-11-17 | ~~Created with 2 rows after this report~~ | ~~Must be maintained per future report or it rots into the exact live-index-rot class it guards against~~ | ~~Convention discipline~~ | ~~S~~ |
| ~~b3~~ | ~~**Harvest of THIS report**~~ done — harvest ran the same night (TODO rebuild + 00-01 pareto plan) | ~~§f below is written harvest-ready~~ | ~~Not yet applied to TODO_LIST/ROADMAP — you said WAIT FOR INSTRUCTIONS~~ | ~~Your go~~ | ~~S~~ |

## c) NOT STARTED

All carried in `TODO_LIST.md` (this session routed, none executed — correct: docs-health was the mandate):

- ~~**CI pin fix + green master** — `[ready]`, Critical. Root cause verified this session (422), fix is code work, deliberately not done under a docs mandate.~~ done at `5a9a8ee`
- ~~**Hardened-unit live smoke test** — `[ready]`; gates the SystemNix cutover.~~ done 2026-10-17 (`25e05af`)
- ~~**SystemNix cutover execution** — `[watch]`; unblocked (push landed), waiting on the smoke test.~~ done 2026-10-16 (owner-directed, ahead of the gate)
- ~~**LICENSE decision, tag v0.1.0 + release polish, demo GIF, VM test, observability, demo mode, IPv6 leg, claim cleanup, sandbox-contract granularity, aarch64/channel/formatter/optionDoc decisions** — all rowed with sources.~~ all shipped across 2026-10-17 (T03–T21)
- ~~**ANNOTATE of the 23-28 report** — intentionally not started: HARVEST (done, a5) reads forward and never edits the source; nothing has shipped since it was written, so there is nothing to resolve backward yet.~~ resolved by this pass (2026-11-17 — every item in the 23-28 report now carries a verdict)

## d) TOTALLY FUCKED UP

1. ~~**I almost edited AGENTS.md against a stale snapshot.** My session-context copy still said "remote not yet created"; the disk file had been fixed by the prior session's daemon commit. I drafted findings (stale-remote Critical/Medium) that did not exist on disk. Caught it only because I re-read exact bytes before editing. Root cause: trusting the context snapshot over disk truth. Had I skipped that read, I would have "corrected" already-correct claims and shipped a wrong findings table.~~ done — the disk-truth rule has governed every audit since
2. ~~**I watched `.config/metadata.yaml` get committed and did nothing.** I noticed the untracked tool-generated file (23:49, `tags: []`), flagged it in my report — and left it in the daemon's reach. It is now in git history (commit `f9308d6` batch). If it's junk, removing it later means history surgery or a follow-up commit; trashing/gitignoring it before the daemon swept was a 10-second action I did not take. Severity: low (95 bytes), but it is exactly the "noticed and deferred" drop the 23-28 report's own §d4 complained about.~~ done — resolved — kept; creator identified (meta-lint --fix, PM001)
3. ~~**I did not inspect the daemon's mid-session commits.** Three auto-commits landed while I worked (f9308d6, 0788657, fff0b61). I verified the final tree state (gate green, files as intended) but never diffed what the daemon actually staged — e.g. whether `f9308d6` bundled anything beyond FEATURES/ROADMAP/.config. Trusting the heuristic committer with unreviewed batches is how surprises ship.~~ done — reviewed in the 00-01 pareto plan errata
4. ~~**The "gen 904" provenance claim went unverified.** I verified every SystemNix file path and the option parity, but never confirmed SystemNix is actually on generation 904 — the number is inherited from AGENTS/CHANGELOG prose and I did not list it under "could not verify" in the health report. An auditor citing an unverified number without flagging it is the exact class docs-health exists to catch.~~ done — gen 904 verified 2026-10-17 (T16)
5. ~~**Severity classification wobble in the health report.** I waffled (internally) over whether the README `follows`-line and sandbox-bullet omissions were Accuracy-Low or Fitness-Low; the final table/lines are consistent and the shown math is a pure function of the table, but the classification reasoning for omissions-vs-false-claims deserves an explicit rule, not per-instance judgment.~~ done — superseded — severity rules live in the docs-health skill verify-checklist

## e) WHAT WE SHOULD IMPROVE

1. ~~**Disk-truth rule for audits** — findings must be tallied from files read at audit time, never from session-context snapshots. This session nearly shipped phantom findings (§d1).~~ done — standing disk-truth rule — applied in this pass
2. ~~**Standing drift gate** — the repo's `module-contract` pattern (assert unit text) extends naturally to docs: a flake check re-deriving FEATURES/TODO claims (option count, env-var names, row statuses) would mechanize what tonight was manual. Roadmap-grade idea.~~ done — shipped as docs-drift (2026-10-17, T19)
3. ~~**Markdown formatter fate needs deciding sooner** — six markdown docs now exist under zero format enforcement (dprint.json inert, treefmt Nix-only). The decision row is rowed; until then every future session hand-formats markdown by eye.~~ done — decided — markdown hand-formatted by recorded decision (2026-10-17)
4. ~~**Untracked-file hygiene during daemon operation** — anything noticed-and-unowned in the tree gets swept by the daemon within minutes. Decide fast (trash/gitignore/keep) or it commits itself (§d2).~~ done — crush-config lessons carry the daemon-hygiene entries
5. ~~**TODO_LIST could carry Impact/Effort columns** — the rebuilt queue is section-ranked but unranked within sections; a pareto-planning pass would make the 21 rows actionable in order. Also: 21 rows for a young repo is the upper bound of healthy — next additions should require deleting something.~~ **Won't implement — superseded by the lifecycle-tag format TODO_LIST adopted.**
6. ~~**Provenance numbers get verified or flagged** — "gen 904" class claims: either check them (SystemNix is a sibling checkout — cheap) or mark them unverified in the audit report (§d4).~~ done — gen 904 verified 2026-10-17
7. ~~**AGENTS.md could gain a one-line pointers block** to FEATURES.md/ROADMAP.md as high-value references — currently a fresh session discovers them only by listing the root. One line, zero duplication (pointers, not content).~~ done — AGENTS Inventory pointers line added (T16)

## f) Up to 50 things to get done next

> Ranked by impact. Most items 1–12 are already rowed in TODO_LIST.md (marked ✎ rowed) — harvest should dedupe, not duplicate. Items beyond ~15 are routing candidates (ROADMAP/decline). Written HARVEST-ready; NOT yet applied — you said wait.

| #  | Task                                                                                                                                            | Impact   | Effort | Category      |
| -- | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------ | ------------- |
| ~~1~~  | ~~Harvest THIS report's §f into TODO_LIST/ROADMAP (docs-health HARVEST) — mostly a no-op vs the rebuilt TODO_LIST; verify, don't re-row~~ done — the 00-01 pareto plan + later audits harvested and deduped | ~~High~~ | ~~S~~ | ~~Process~~ |
| ~~2~~  | ~~Fix the `nix-installer-action` pin (422-verified fabricated SHA) + `permissions`/`persist-credentials` hygiene; get master green ✎ rowed~~ done at `5a9a8ee` | ~~Critical~~ | ~~S~~ | ~~Bug~~ |
| ~~3~~  | ~~Decide aarch64 strategy (QEMU/binfmt vs drop the system) ✎ rowed~~ done — KEPT + binfmt CI (2026-10-17) | ~~High~~ | ~~S–M~~ | ~~Decision~~ |
| ~~4~~  | ~~Hardened-unit live smoke test (`systemd-run --user` + `quickshell -p`; render, ping, click-dismiss, Qt warnings, RSS vs MemoryMax) ✎ rowed~~ done at `25e05af` | ~~High~~ | ~~S–M~~ | ~~Verification~~ |
| ~~5~~  | ~~Decide `.config/metadata.yaml` fate: trash + gitignore, or keep — it is now committed (this session's §d2)~~ done — kept — creator identified (meta-lint --fix, PM001 mandates it fleet-wide) | ~~Medium~~ | ~~S~~ | ~~Cleanup~~ |
| ~~6~~  | ~~Review the daemon's mid-session commits (`f9308d6`..`fff0b61`) for anything swept beyond intent~~ done — reviewed in the 00-01 pareto plan errata (nothing unexpected swept) | ~~Medium~~ | ~~S~~ | ~~Cleanup~~ |
| ~~7~~  | ~~Verify the "gen 904" provenance number against SystemNix or flag it unverified in AGENTS/CHANGELOG (this session's §d4)~~ done — gen 904 verified 2026-10-17 (live-session report anchor) | ~~Low~~ | ~~S~~ | ~~Documentation~~ |
| ~~8~~  | ~~One-off `systemd-analyze verify` on the generated unit text; automate as flake check after feasibility ✎ rowed~~ done — shipped as unit-verify | ~~High~~ | ~~S~~ | ~~Verification~~ |
| ~~9~~  | ~~Gate the SystemNix cutover on #4, then execute it (input, relock, thin wrapper, parity, delete in-tree module, AGENTS Consumers update) ✎ rowed~~ done — cutover 2026-10-16; smoke 2026-10-17; AGENTS Consumers maintained (lock 320be2a) | ~~Critical~~ | ~~M–L~~ | ~~Feature~~ |
| ~~10~~ | ~~Add AGENTS.md one-line pointers to FEATURES.md/ROADMAP.md~~ done — AGENTS Inventory pointers line (T16) | ~~Medium~~ | ~~S~~ | ~~Documentation~~ |
| ~~11~~ | ~~LICENSE decision ✎ rowed~~ done — MIT owner-confirmed 2026-10-17 | ~~Medium~~ | ~~S~~ | ~~Decision~~ |
| ~~12~~ | ~~Tag `v0.1.0` + GitHub Release + repo topics + CI badge once green ✎ rowed~~ done at `fc2577e` | ~~Medium~~ | ~~S~~ | ~~Release~~ |
| ~~13~~ | ~~Extend `sandboxInUnit` contract to every sandbox line ✎ rowed~~ done — all 22 sandbox lines asserted (T07) | ~~Medium~~ | ~~S~~ | ~~Quality~~ |
| ~~14~~ | ~~Decide dprint.json fate and wire-or-drop; give markdown a formatter gate ✎ rowed~~ done — dprint dropped, decision recorded (T09); zombie source later identified (BuildFlow) | ~~Medium~~ | ~~S~~ | ~~Cleanup~~ |
| ~~15~~ | ~~Decide BuildFlow coverage (`.buildflow.yml` vs trim the managed .gitignore block) ✎ rowed~~ done — .gitignore block trimmed (T09) | ~~Medium~~ | ~~S~~ | ~~Cleanup~~ |
| ~~16~~ | ~~Resolve nixpkgs channel intent (`nixpkgs-unstable` vs `nixos-unstable`) + consumer-follows policy ✎ rowed~~ done — nixos-unstable (T10) | ~~Medium~~ | ~~S~~ | ~~Decision~~ |
| ~~17~~ | ~~State-transition observability (journal show/hide + `offline_banner_active` gauge) ✎ rowed~~ done at `4cff63a` | ~~High~~ | ~~M~~ | ~~Feature~~ |
| ~~18~~ | ~~VM/negative test (`OFFLINE_BANNER_SYSROOT` + probe injection) ✎ rowed~~ done — probe-transitions shipped (T13) | ~~High~~ | ~~L~~ | ~~Test~~ |
| ~~19~~ | ~~IPv6 leg or documented v4-only tradeoff ✎ rowed~~ done — documented v4-only tradeoff (T14) | ~~High~~ | ~~S–M~~ | ~~Feature~~ |
| ~~20~~ | ~~Demo mode `OFFLINE_BANNER_DEMO=1` ✎ rowed~~ done at `f1dacf7` | ~~Medium~~ | ~~S~~ | ~~Feature~~ |
| ~~21~~ | ~~Claim cleanup: DMS layer-shell claim verify-or-soften; iface-list cross-ref to wifi-failover QML ✎ rowed~~ done — claim softened + cross-ref (T16) | ~~Medium~~ | ~~S~~ | ~~Documentation~~ |
| ~~22~~ | ~~CI hardening once green: branch protection, dependabot/renovate, actionlint/zizmor ✎ rowed~~ done — branch protection + dependabot 2026-10-17; actionlint+zizmor wired `9ace19a` (2026-11-05) | ~~Medium~~ | ~~S~~ | ~~Quality~~ |
| 23 | Live-verification debts: reboot auto-start, multi-monitor, click-dismiss harness ✎ rowed **→ TODO_LIST live-verification debts row** | Medium   | M      | Test          |
| ~~24~~ | ~~`failuresToShow` sanity bound ✎ rowed~~ done — eval bound (T20) | ~~Low~~ | ~~S~~ | ~~Quality~~ |
| ~~25~~ | ~~`restartTriggers` drift-guard assertion ✎ rowed~~ done — restartTriggers assert (T20) | ~~Low~~ | ~~S~~ | ~~Quality~~ |
| ~~26~~ | ~~OptionDoc render check decision ✎ rowed~~ done — decision recorded — README table surface (T21) | ~~Low~~ | ~~S~~ | ~~Decision~~ |
| ~~27~~ | ~~Demo GIF for README ✎ rowed~~ done at `9ab577b` | ~~Low~~ | ~~M~~ | ~~Documentation~~ |
| ~~28~~ | ~~Consider a docs drift gate (flake check re-deriving FEATURES/TODO facts — extends the module-contract pattern)~~ done — shipped as docs-drift (T19) | ~~Medium~~ | ~~M~~ | ~~Quality~~ |
| ~~29~~ | ~~Formalize the omissions-vs-false-claims severity rule from this session's §d5 into the docs-health mental checklist when next auditing~~ **Won't implement — declined in the 00-01 pareto plan — skill-repo concern, not repo work.** | ~~Low~~ | ~~S~~ | ~~Process~~ |
| ~~30~~ | ~~Pareto-rank the rebuilt TODO_LIST (21 rows) with the pareto-planning skill~~ done — executed as the 00-01 pareto plan (2026-10-17) | ~~Medium~~ | ~~S~~ | ~~Process~~ |

(31–50 intentionally left un-brainstormed: the 23-28 report's §f backlog was fully harvested tonight — re-listing it here would duplicate TODO_LIST, the exact entombment-in-reverse failure docs-health warns about.)

## g) Questions only you can answer

1. **`.config/metadata.yaml`** — it is tool-generated (created 23:49 tonight, `tags: []`), was untracked, and the daemon has now committed it. Trash + gitignore, or is it yours/needed by something? I cannot tell what created it (95 bytes, no provenance I can verify from this repo). **→ answered — kept; creator identified (meta-lint --fix, PM001 mandates it fleet-wide)**
2. ~~**DOMAIN_LANGUAGE.md** — I deliberately declined to create it (6-term domain, already defined in module.nix's header + README; a third copy drifts). The skill treats it as a standard file and the fitness formula counts must-haves. Keep it declined, or do you want the glossary anyway?~~ **Won't implement — declined — the 6-term domain is documented in module.nix header + README; a third copy would drift (reaffirmed 2026-11-17).**
3. ~~**Harvest timing for THIS report** — §f above is written harvest-ready and §(b3) holds it back per your "WAIT FOR INSTRUCTIONS". Say "harvest" and I'll run docs-health HARVEST (expected: near-no-op — #5, #6, #7, #10, #28–#30 are the only new rows; the rest are already rowed).~~ done — harvest ran the same night (00-01 pareto plan + TODO rebuild)

---

_Point-in-time snapshot — will go stale. Section (f) is HARVEST-ready on your instruction; report picked up by the auto-commit daemon (manual commit skipped: harness forbids commits without explicit request)._
