# Status: website-CI repair, plan shipped, parallel execution in flight

**Scope.** This report covers the session arc AFTER the 18:52 postmortem (planning directive → website repair → push → TS7 research → this report). VERIFIED, with artifacts: the red Website pipeline's root cause (daemon commit `2ccdf6e` diff: five dep bumps + forbidden `typescript ^7.0.2`, no lock regen; failing run 40881107334 died at `pnpm install`); the repair (lock regen under the 24 h gate → `typescript@6.0.3`, `@astrojs/check@0.9.12`, `astro@7.4.5`; `astro check` 0 errors, build 10/10 + CSP 10/10, `html-validate` exit 0); the push (`2ccdf6e..97b8056`) and its CI verdicts (Website **✓ + deployed**, 43 s + 26 s; Checks **✓** 5 m 10 s — master fully green for the first time since 2026-10-29); TS7 upstream state (five primary sources with dates: withastro/astro #17268/#17336/#18053/#17852/#18589 + `@astrojs/check` peer metadata via pnpm); and the unexplained working-tree diffs in `flake.nix`/`module.nix` (read in full, plus one read-only `module-contract` build of the in-flight tree: **green**). NOT verified: the full correctness of the in-flight parallel work (only eyeballed + one fast gate; `nix flake check --all-systems` not run on it), the identity of its author, and CI for anything after `97b8056`.

---

## Direct answers: forgot / better / improve

**What did I forget?**

1. **The AGENTS git rule "check `git log` immediately before committing"** — I knew the daemon commits every few minutes, ran a multi-commit chain without the precheck inside it, and got raced: the daemon had committed the plan file, so my soft-reset landed on the wrong commit and produced `4842332` (website fix + plan file under a `fix(website)` message, docs commit never ran, push aborted). Caught only because the `&&` chain stopped on the empty second commit and my `git show --stat` verifications were inside the chain. Repaired atomically before push — but it was luck-assisted discipline, not discipline.
2. **The pushed plan file contains a thinko artifact**: task F13 reads "Fold CHANGELOG [Unreleased] → [0.2.0.1… no: 0.2.1]" — my mid-sentence self-correction, committed to a public repo. I never re-read the file after writing it.
~~3. **S1–S4 (the TS7 hardening solutions) live only in chat** — not harvested into TODO_LIST/plan; if this session dies, they die with it.~~ done at `3a34f37`, `d999eb6` — S2 shipped (CI TypeScript-major guard), S4 shipped (ci-watch sentinel); S3 pre-commit hook still open (see line 81)
4. First TS7 gate-string grep silently searched nothing (rg does not follow the `node_modules` symlinks); I treated "no output" as "not found" once before noticing and re-running against the real `.pnpm` paths.

**What could I have done better?**

1. One atomic git chain INCLUDING `git log --oneline -1` as step zero — the race window was minutes wide and I knew it existed.
2. Re-read the plan file once before committing it (the F13 artifact and any formatting would have surfaced).
3. Noticed the parallel executor earlier: `flake.nix`/`module.nix` changed under me between my push and this report request; I only discovered it because the status-report protocol made me run `git status` fresh.

**What could we still improve?**

~~1. **Multi-writer coordination** — there are now up to THREE writers on this tree (me, the auto-commit daemon, and a parallel plan executor). Without a handshake (one executor at a time, or branch-per-executor), commits WILL collide; today it was only luck that my push went out before their edits landed.~~ done at `9ed4849` — parallel-session claim-file protocol (docs/status/.session-claim) live and first-day-proven; daemon-side skip stays owner work (TODO row: Session-claim protocol)
2. Commit-race-proof procedure (precheck-in-chain), post-write re-read of public docs, and immediate harvesting of in-chat proposals.
3. `rg --follow` (or `.pnpm` real paths) discipline for node_modules greps.

---

## a) FULLY DONE

1. **M01 — Website pipeline repaired, everything pushed, master fully green.** Root cause: daemon auto-commit `2ccdf6e` swept dependency bumps without lock regen (the codified pnpm rule) AND included `typescript ^6.0.3 → ^7.0.2` (silently disables `astro check`). Repair: TS reverted to ^6.0.3, harmless bumps kept, lock regenerated under `minimumReleaseAge`, full local verify, commits `8359661` (fix) + `97b8056` (docs, after the race repair), pushed `2ccdf6e..97b8056`. CI: Website ✓ (build 43 s, deploy 26 s — first green + deploy since 2026-10-29), Checks ✓ (5 m 10 s, both systems). **The v0.2.1 release gate (both workflows green on HEAD) is satisfied.**
~~2. **Comprehensive pareto plan written, committed, pushed**: `docs/planning/2026-11-05_19-03_never-again-pareto-execution-plan.md` — 1%/4%/20% + other-20% breakdown, mermaid execution graph, 4 decision gates (D1–D4), 27 medium tasks (30–100 min, ~13.5 h), 81 fine subtasks (≤12 min), standing rules; six errata against TODO_LIST (closed squash item, stale FIREBASE row, the false "systemd creates ReadWritePaths dirs" assumption that WAS the incident, dprint.json zombie #3, the red Website pipeline, dependabot unchanged).~~ done at `97b8056` — never-again pareto plan written, committed, pushed
~~3. **TypeScript 7 upstream status — researched and verified with primary sources**: the astro TS7 path is the merged `@astrojs/ts-content-mapper` (works with `typescript@next` 7.1+ for tsc); `astro check` full support waits on withastro/astro#17852 (OPEN) + TS 7.1 ("still far from release", astro team 2026-09-17); `@astrojs/check@0.9.12` peer still `^5 || ^6`; the silent-exit-0 trap fixed in #18589 (merged 2026-11-02, ships in astro 7.4.6 — our lock resolved 7.4.5). `[watch]` row added to TODO_LIST.md with trigger signals + migration procedure.~~ done — TS7 upstream research with primary sources; watch row landed separately (825d43b)
~~4. **Solutions matrix S1–S6** for the TS7 exposure, with recommendation: S1 (pnpm `overrides` pin) + S2 (CI major-version guard) now; S3 (pre-commit manifest-lock hook) + S4 (ci-watch workflow) as plan tasks; S5/S6 rejected with reasons.~~ done — S1-S6 matrix with recommendation, kept in chat/plan
~~5. **Daemon-sweep hygiene**: both of this session's meaningful changes are real commits (`ad6cac3` earlier; `8359661`/`97b8056` now) — no unpushed chore-swept work of mine remains.~~ done — session's changes landed as real commits ad6cac3/8359661/97b8056

## b) PARTIALLY DONE

1. ~~**⚠ Parallel plan execution in flight in this working tree — NOT authored by me.** Uncommitted diffs implement M09 (derived ReadWritePaths: `provisionedRuntimeDirs`/`provisionedStateDirs` as single source of truth), M10 (computed `rwProvisioned` invariant + synthetic-hole teeth fixture), M15 (negative fixtures: inert opt-out eval, `badLedgerAsserts`, `badRelativeLedgerAsserts`), M16 (link-cue positive assert in probe-transitions, with deterministic count logic). Quality looks high and matches the plan spec; a read-only `module-contract` build of the in-flight tree is **green**. Author unknown — presumably your other session running the plan's Full Execution Mode. Per the never-touch-unauthored-changes rule I have not modified or committed any of it.~~ done — owned — the in-flight work shipped as `2cc6a16` (the 19:56 session; verification stack in its §a, negative proofs in its §b)
2. ~~**Plan hygiene debt**: F13 thinko artifact in the pushed plan; S1–S4 not yet in TODO_LIST/plan.~~ done — F13 artifact fixed inline 2026-11-17 (the plan file now reads cleanly); S1+S2 harvested as a TODO row 2026-11-17 (S3/S4 remain plan ideas)
3. ~~**TODO_LIST.md** carries the uncommitted `[watch]` TS7 row (daemon will sweep it into a chore unless committed deliberately).~~ done — committed — the TS7 watch row is live in TODO_LIST
4. ~~**M02 (v0.2.1 release)**: unblocked and fully staged (master green, CHANGELOG entry ready to fold) — awaiting your D2 go; tagging is owner-gated by runbook.~~ done — still staged — the v0.2.1 gate is green; the tag stays the owner decision (TODO row)

## c) NOT STARTED

M02 (release), M03 (SystemNix lock bump + switch), M04/M05 (live-proof evening / demo pixel proof), M06/M07 (VM smoke test skeleton + CI wiring, D1), M08 (waybar `stale` deploy), M11 (`nix run .#smoke`), M12 (ANNOTATE old reports), M13 (HARVEST — partially superseded: I added the TS7 watch row directly), M14 (cross-project lesson + daemon-manifest rule), M17–M27 (long tail). S1/S2 implementation. astro 7.4.6 bump (rides M23's intentional round).

## d) TOTALLY FUCKED UP

1. **The daemon race into a mixed commit** (`4842332`: website fix + plan file under a `fix(website)` message; docs commit silently skipped; push aborted mid-chain). Recovered with an atomic reset+restructure before anything left the machine — but the AGENTS precheck rule existed precisely for this and I skipped it.
2. **A public, pushed planning document containing a mid-sentence thinko** ("0.2.0.1… no: 0.2.1") — I shipped prose I never re-read.
3. Carried from earlier today, both now RESOLVED: the week-red Website pipeline (daemon-swept TS7 + lock drift — found, fixed, green, deployed) and the 226/NAMESPACE dead-unit incident (see the 18:52 report; fix pushed, host live, release pending).

## e) WHAT WE SHOULD IMPROVE

~~1. **One executor per tree, or branches per executor** — me + daemon + parallel session is two writers too many; today's push won a race it didn't know it was running.~~ done at `9ed4849` — claim-file protocol shipped 2026-11-18; daemon claim-awareness still open (TODO row: Session-claim protocol: daemon claim-awareness)
2. Precheck-inside-the-chain git discipline; re-read anything public before push; harvest in-chat proposals immediately (chat is where tasks go to die).
~~3. The daemon must never own dependency manifests (M14 rule; `2ccdf6e` is the standing proof) — S3's pre-commit hook makes it mechanical.~~ **→ TODO_LIST row "Daemon policy for junk commits and dependency manifests"**
~~4. Red-master detection (S4): twice now a red pipeline sat unnoticed for days; visibility should not depend on someone running `gh run list` by accident.~~ done at `d999eb6`, `38c3bcb` — ci-watch scheduled sentinel detects red master (race fix 38c3bcb)

## f) What to get done next (impact-ordered; plan IDs in parens)

~~1. Handshake with the parallel executor: who/what is editing flake.nix + module.nix — I stand down and verify after, or it stands down?~~ done — superseded (2cc6a16) — question moot: the 19:56 session owned and shipped the in-flight M09/M10/M15/M16 work
~~2. Verify the in-flight M09/M10/M15/M16 work fully (`nix flake check --all-systems`) once the executor signals done; then one clean commit.~~ done at `2cc6a16` — in-flight work verified with full gate stack and committed
~~3. Cut v0.2.1 (M02, D2) — gate satisfied, staged.~~ done at `ad3bdc2`, `a5c19ee` — v0.2.1 tagged 2026-11-18 (ad3bdc2); v0.2.2 followed the same day (a5c19ee)
4. ~~SystemNix lock → v0.2.1 + switch + post-switch verify (M03).~~ done — superseded — SystemNix consumed master directly through the cutover waves (lock 320be2a; gen 995 live)
5. ~~Forced-outage live-proof evening: cue + pixels + first ledger entry (M04).~~ done — half-done — the gen-995 genuine outage proved the ledger write + fired the show cue; audibility + pixels remain (forced-outage evening row)
6. Implement S1 (pnpm TS override) + S2 (CI TS-major guard). **→ TODO TypeScript-pin row (S1+S2, harvested 2026-11-17)**
7. ~~Fix the plan's F13 artifact; harvest S1–S4 into TODO/plan.~~ done — F13 fixed inline 2026-11-17; S1+S2 rowed 2026-11-17
~~8. Waybar `stale` consumer on evo-x2 (M08) — the dead-banner tell, deployed nowhere.~~ **→ TODO_LIST row "Bar-side consumer live wiring (systemnix-banner DMS plugin) + stale-tell proof"**
9. ~~VM smoke skeleton (M06) + D1 policy + CI wiring (M07).~~ done — packages.vm-smoke shipped (2cc6a16, negative-proven); the CI-policy decision stays D1
10. ~~`nix run .#smoke` app (M11).~~ done — (2cc6a16 — nix run .#smoke + the smoke-script gate)
~~11. ANNOTATE the 2026-10-29 reports + FEATURES sound row (M12).~~ done at `825d43b`, `67f9ac9`, `c733efc` — M12 annotations landed 2026-11-05; the 2026-11-17 corpus sweep completed them; the FEATURES sound row carries the live evidence
~~12. HARVEST the plan into TODO_LIST/ROADMAP + apply the six errata (M13).~~ done at `74e1145` — never-again execution harvested into the living docs (TODO, ROADMAP, AGENTS) with the errata applied
~~13. Cross-project lesson into crush-config lessons.md + AGENTS daemon-manifest rule (M14).~~ **→ TODO_LIST row "lessons.md: an auto-commit daemon must never own dependency manifests"**
14. ~~render-smoke determinism audit (M17).~~ done — 2026-11-05 — audited; the doctrine was already applied (wait_pixel)
15. ~~actionlint + zizmor wired (M18).~~ done at `9ace19a`
~~16. S3 pre-commit manifest-lock hook.~~ **→ TODO_LIST row "Daemon policy for junk commits and dependency manifests"**
17. S4 ci-watch scheduled workflow. **→ TODO website-CI quality-jobs row (S4 ci-watch)**
18. astro 7.4.6 + the pnpm update round under the age gate (M23 — also carries the exit-1 fix #18589). **→ rides the intentional pnpm update round (never-again M23 procedure); blocked upstream on TS 7.1 anyway**
19. ~~IAM grant → Terraform (M19).~~ done — encoded d161aee (apply owner-side)
20. ~~play-sounds.sh + audition all 12 cues (M20).~~ done — scripts/play-sounds.sh + packages.sounds shipped (569a4fe); the audition itself stays owner ears
21. ~~Waybar `since` support + shellcheck gate for contrib (M21).~~ done — (569a4fe — since rendering + the shell-scripts gate)
~~22. Launch posts update + post (M22, owner-gated).~~ **→ TODO_LIST row "Owner console one-offs"**
23. ~~Dependabot 20-alert triage (M23b).~~ done — by-events — 0 open alerts (2026-11-05)
~~24. Tag-trigger CI decision (M24).~~ done at `373690e` — decided 2026-11-18: no tag-trigger CI (AGENTS decision records)
25. ~~v6 probeHost doc example (M25).~~ done — the v6 probeHost worked example shipped in configuration.mdx
26. ~~jq ledger cookbook (M26).~~ done — the jq ledger cookbook shipped in observability.mdx
~~27. Hygiene sweep: dprint.json #3 decision, social-preview verify, errata application (M27).~~ **→ TODO_LIST rows "Owner console one-offs" (social-preview upload) and "D4 — kill the BuildFlow zombie class" (dprint.json); the errata landed at 74e1145**
28. ~~Post-switch: update AGENTS Consumers lock rev (M03 tail).~~ done — 2026-11-17 — AGENTS Consumers carries the lock waves + gen-995 evidence
~~29. Consider branch-per-executor policy for parallel sessions (new, from today's race).~~ done — superseded (9ed4849) — resolved by the claim-file protocol (docs/status/.session-claim) instead of branches

## g) Questions I cannot figure out myself

~~1. **Who is executing the plan in `flake.nix`/`module.nix` right now?** (M09/M10/M15/M16-class diffs, uncommitted, module-contract green, not mine.) Should I stand down on those files and verify after they finish — or should they stop so I finish and commit?~~ done — answered 2026-11-05: the 19:56 never-again execution session; its in-flight work shipped as 2cc6a16
2. **D2: cut v0.2.1 now?** Master is fully green on `97b8056`, the CHANGELOG entry is ready to fold, SystemNix is waiting on the tag. Tagging is owner-gated by your own runbook. **→ still the owner decision — the gate is green, the CHANGELOG is staged (v0.2.1 TODO row)**
3. **Go on S1+S2** (pnpm TypeScript override + CI TS-major guard, ~20 min) — and should S3/S4 join the plan as M-tasks? **→ S1+S2 rowed 2026-11-17 (TypeScript pin + CI guard); S3/S4 stay plan ideas pending owner go**

---

_Point-in-time snapshot, 2026-11-05 19:25 CET. Historical — never rewritten; harvest forward via docs-health._
