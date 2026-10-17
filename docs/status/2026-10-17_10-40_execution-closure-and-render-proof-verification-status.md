# Execution-Closure Status Report — return-state triage, render proof verified, docs pass

*Point-in-time snapshot, 2026-10-17 10:40 CEST, HEAD `9c178b7`, working tree clean
(daemon committed everything mid-session). Scope: ONLY this session's run — the
standing execution mandate applied to the closure work queued by
`2026-10-17_09-36_check-extension-and-render-proof-status.md`. Sections follow
the a–g dispatch shape. When bringing this report current, use docs-health
ANNOTATE.*

## a) FULLY DONE (verified, not claimed)

1. **Return-state triage — my prior session survived intact.** All key changes
   verified present at `a91a77a`/`9c178b7`: structured journal tokens +
   `XDG_CACHE_HOME` in `module.nix`, `render-smoke` + extended
   `probe-transitions` + `cacheDirSet` in `flake.nix`, `contrib/offline-banner-waybar`,
   AGENTS runbooks, README bullets, the 09:36 report (committed as `8b87ca0`).
   Other sessions also deflaked my probe-transitions asserts three times
   (`cade264`, `39d51bf`, `8a14308`) — semantics preserved, CI-green.
2. **`dprint.json` zombie executed.** Timeline reconstructed via
   `git log --follow`: added 23:19 (`f53814b`) → deleted 00:49 WITH the recorded
   decision (`6d429aa`; TODO row DONE + AGENTS hard rule) → **byte-identical
   re-add 01:35 (`dabd06f`) by the daemon** from a tooling artifact (identical
   md5, zero invokers repo-wide, no `.buildflow.yml`). Trashed + deletion
   staged; the daemon committed it. The recorded decision stands; the docs did
   not get reconciled downward to match an accident.
3. **The 7-hour hung capture job killed.** `wf-recorder` (PID 1866126) + the
   capture script (1860327) from 03:04 were still alive — `wf-recorder` ignores
   SIGINT once its compositor connection is dead. `pkill`'d both.
4. **Scratch trashed (Q2 default executed).** `/tmp/offline-banner-demo/`,
   `/tmp/qsprobe`, `/tmp/uvroot`, and the stale top-level
   `/run/user/1000/offline-banner.state` (01:44 artifact of an intermediate QML
   revision) — all via `trash`. The REAL live dir
   `/run/user/1000/offline-banner/` was correctly left alone: **a real
   offline-banner unit is running on this machine right now** (state file
   heartbeat current, `active:false`, `failures:0`).
5. **Q1 (zero outputs) ANSWERED with evidence — not a banner bug.** The only
   compositor is niri PID 5049 (session pair) with zero outputs on all four
   sockets; DRM ground truth: `card1-DP-1` **connected but disabled**; the
   owner is actively using the machine over SSH (many pts sessions). The niri
   session is displayless by circumstance; the banner unit under it behaves
   exactly as the README startup-race paragraph documents (probe alive, state
   truthful, no surfaces). Live proof of the fail-open design, incidentally.
6. **`scripts/capture-demo.sh` root-cause fixed, lint-clean, re-run green.**
   Two real bugs: (a) `kill -INT; wait` on `wf-recorder` hangs forever after
   the compositor dies → poll-then-SIGKILL escalation; (b) the cached
   `shell.qml` guard was the stale-provenance trap (the 03:04 PNG was captured
   from a 00:06 QML) → cache removed, ground truth re-extracted every run.
   shellcheck + shfmt clean.
7. **Demo assets regenerated from CURRENT ground truth (10:14)** —
   `offline-banner-demo.webp` (99 K) + `.png` (25 K). Then **§f-1/§b-4 of the
   01:59 report CLOSED properly**: 179 frames extracted and inspected —
   yellow-strip scan: hidden frames 001–099, banner 100–175, slide-up tail
   176–179; eyeballed frame 098 (mid push-down, partial strip), 120 (settled
   strip under the bar), 177 (mid slide-up). Push-down AND recovery slide-up
   both visible and animated. `banner.log` proves the full lifecycle with the
   NEW journal tokens (`state=shown` → 3× `probe failed` → `probe ok
   recovered_after=3` → `state=hidden`).
8. **Nine cross-project lessons committed to crush-config** (`4f6dd31`,
   pre-commit hook green): the 01:59 §f-50 quartet (%t, mkdirat, jq `//`,
   negative-test semantics) plus poll-don't-sample, poll-then-SIGKILL,
   pixel-asserts-on-the-shipped-encoding, repro-before-suppression, and
   daemon-zombie-deletions. NOTE: deploys to `~/.config/crush` only on the
   next home-manager activation.
9. **SystemNix handoff annotation.** `../SystemNix/docs/todo/desktop.md` v3
   deploy row: smoke gate marked DONE (2026-10-17 evidence), render-smoke
   noted, relock pointer updated `78aa7fc+` → `a91a77a` with the new-content
   list; switch explicitly left owner-gated.
10. **Dependabot triage.** 0 open PRs, 20 alerts (up from 19, website
    transitive deps, non-gating). Did NOT regenerate `website/pnpm-lock.yaml` —
    that subtree has an active session; crossing workstreams for a non-gating
    cleanup is worse than waiting. TODO row refreshed with today's evidence.
11. **Living docs updated (all daemon-committed).** CHANGELOG `[Unreleased]`
    extended (render-smoke, waybar consumer, AGENTS runbooks under Added;
    journal-tokens + extended probe-transitions + regenerated assets under a
    new Changed; cache fix + capture-script fixes under Fixed) + keep-a-changelog
    compare-link footer at the file bottom. TODO_LIST: live-verification row's
    RENDER LEG closed with evidence (headless pixels CI-proven, demo
    frame-watched; only real-monitor visibility remains, riding the switch);
    NEW row: render-smoke determinism audit (harvested from the 10:06 report
    §f-10, was unrouted). FEATURES re-verified: header evidence line, intro
    note rewritten (headless pixel proof exists; PARTIALLY rows now narrow to
    real-monitor only), strip/animation rows cite render-smoke + frame watch,
    observability row documents the token contract, NEW waybar-consumer row,
    "4 gates" row corrected to **7 gates**, PLANNED row narrowed.
    `docs/status/README.md` indexed the 09:36 report.
12. **Annotation pass prepared and tool-validated.** Dry-run of the docs-health
    `annotate.go` prose mode succeeded against 01:59 §b (3 specs, exact
    placement verified). Full spec sets are drafted (below, §b-1).

## b) PARTIALLY DONE

1. **The ANNOTATE pass itself is NOT applied.** Dry-run validated only. Drafted
   specs awaiting application: 01:59 §b items 1/3/4 (done-verdicts), §f items
   1, 5–17, 28, 48–50 (done), §g 1–3 (routed answers: MIT owner-confirmed /
   zero-outputs answered / gauge answered by the waybar consumer); my 09:36
   §f items 1–10, 26–30 and §g 1–3 (all three resolved this session). Items
   2/4/18–27/29–47 of 01:59 §f stay deliberately untouched (open/roadmap).
2. **Final gates not run since the doc edits** — `nix fmt` +
   `nix flake check --all-systems` pending; in particular `docs-drift` is
   unverified after the FEATURES row changes (option names were preserved, but
   unverified is unverified).
3. **check-rows completeness gate** not run (belongs after the annotations
   land).
4. **Q2 latitude is owner-ratified only retroactively**: the standing mandate
   said "execute until done" and the 09:36 report stated trash-after-confirmation
   as the default; I executed. If you wanted the 01:44 state file kept for
   forensics, say so — /tmp copies are trash-recoverable, the /run one is not.
5. **Lessons not yet active on any host** (committed in crush-config; deploys
   via home-manager activation).

## c) NOT STARTED

1. Applying the drafted annotations (§b-1) + `check-rows` gate + possible
   archive decisions for fully-resolved reports.
2. Final gates (`nix fmt`, `nix flake check --all-systems`).
3. `wlrctl` install + click-dismiss recon (01:59 §f-2 — the named missing tool).
4. Live-monitor render proof (rides the SystemNix switch; recon says the
   current session is displayless by circumstance).
5. Reboot/re-login auto-start proof; real `systemctl --user edit` drop-in
   retune test (both owner-executable; runbook in AGENTS).
6. render-smoke hardening: determinism audit (new TODO row), second pixel row,
   link-reason visual state, artifact upload on failure.
7. v0.1.1 decision/cut (see §g-1).
8. `pnpm update` in website/ (see §g-3).
9. Launch-post posting (owner-gated; the 10:06 session's §g-2 question stands).
10. Longer demo recovery window so the webp shows the full 450 ms slide-up
    (current encode clips it to 4 frames ≈160 ms; visible but tight).

## d) TOTALLY FUCKED UP (process failures — nothing shipped broken)

1. **Probed before looking — repeat offense.** I burned 3–4 tool rounds on
   pixel-range scans that returned "zero yellow" over frames I could have
   simply OPENED (frame 120 showed the banner immediately). The 01:59 report's
   §e-7 was literally "one-watch policy: watch visual assets before declaring
   done" — I repeated the same failure class in probe form. Root cause of the
   probe misses was real and is now a lesson (lossy webp shifts the banner
   yellow outside PNG-calibrated ranges), but the ORDER was wrong: eyes first,
   pixels second.
2. **Prior session's leftovers cost this session real work**: a 7-hour hung
   recorder, a stale-provenance PNG committed into the tree, scratch in /tmp
   and /run, and an undiagnosed hang. The session-end discipline that would
   have prevented all four: sweep background jobs, verify the deliverable by
   eye, clean scratch before yielding. All four are now lessons or fixed code.
3. **CHANGELOG Links block misplaced mid-file** by my own multiedit (between
   [Unreleased] and [0.1.0]); caught on review and moved to the file bottom.
   One avoidable round trip — I structured the edit before checking where
   keep-a-changelog wants link definitions.
4. **annotate.go arg-order failures**: two rejected invocations before reading
   the usage output (flags go after the subcommand; the section prefix is
   positional). Same class as the 01:59 §d-2 exit-code capture: measure the
   interface before driving it.
5. **The demo webp's recovery tail is clipped** (recording window ends ~0.4 s
   into the slide-up). §f-10 below. Cosmetic, but the demo is the storefront.

## e) WHAT WE SHOULD IMPROVE

1. **Eyes-before-probes for anything visual** — extend the one-watch policy:
   eyeball a frame FIRST, then write the pixel assert, calibrated on the
   encoding you ship (lossy webp ≠ lossless PNG).
2. **Session-end sweep as a checklist item**: background jobs (`ps` for stray
   children), scratch paths, deliverable watched once. Every "hung job" incident
   in this repo traces to skipping this.
3. **Read the CLI usage line before the first invocation** of an unfamiliar
   tool — two failed arg orders today.
4. **Triage order confirmed correct**: verify prior work survived → fix zombies
   → execute new work → docs. Keep this order; it caught the dprint zombie
   before it could mislead anyone else.
5. **Cross-workstream courtesy**: never regenerate a lockfile in a subtree
   another session is actively developing (website/pnpm-lock.yaml) for a
   non-gating cleanup — route instead.
6. **Annotation economics**: dig the exact commit hashes BEFORE drafting
   verdicts (done today; the specs are hash-cited and the apply step is now
   mechanical).

## f) Up to 50 things to get done next

**Now (small, from this session's leftovers):**
1. Apply the drafted annotations (01:59 §b/§f/§g + 09:36 §f/§g; specs in this
   session's transcript, dry-run validated) + run `check-rows` on both files.
2. Final gates: `nix fmt && nix flake check --all-systems`; confirm docs-drift
   after the FEATURES edit.
3. Consider archiving the 01:59 report once annotated (every numbered item
   would carry a verdict or stay visibly open — archive only if NOTHING is
   left open; §b-2/§b-5 and §f items 2/4/18–27/29–47 are still open, so it
   stays put for now).
4. Demo capture: extend the post-recovery tail (sleep 4.5 → ~7 s) so the webp
   shows the full slide-up; re-verify frames.
5. `git log` watch: confirm the daemon commits the staged dprint deletion
   under a sane message (it did — verify in the push review).
6. Deploy the lessons: trigger a home-manager switch so `4f6dd31` reaches
   `~/.config/crush/references/lessons.md`.
7. Dependabot: run `pnpm update` in website/ once the website session is idle
   (20 alerts, non-gating).
8. wlrctl install + click-dismiss recon against the live banner (half of T18).
9. SystemNix relock prep: `git diff fff0b61..a91a77a` review draft (the diff
   the switch owner is asked to read — pre-summarize it honestly).
10. README waybar config snippet for the consumer (consumer polish item).

**Next (small-medium):**
11. render-smoke determinism audit (TODO row; doctrine codified by the 10:06
    session) before it flakes in CI like probe-transitions did.
12. render-smoke hardening: second pixel row (strip edge), hidden-vs-shown
    pixel-diff floor, link-reason via sysroot injection, artifact upload on
    failure.
13. Structured journal: startup line with `interval=` + `probe_host=` for
    config forensics.
14. Consumer polish: `-i/--once`, `--max-age` flag, exit codes documented.
15. CI: split checks into named jobs (per-gate badges).
16. Nix output cache to cut ~60 s CI runs.
17. probe-transitions: assert absence of Qt/fatal errors in qs.log (negative
    leg).
18. webp fallback `<picture>`/poster for markdown clients.
19. README architecture diagram (mermaid).
20. Multi-monitor proof via a faked second headless output (fold into
    render-smoke or keep live).
21. Drop-in retune test — owner-executable (`systemctl --user edit` flow).
22. Reboot auto-start proof — schedule with owner.
23. v0.1.1 cut if §g-1 answers "tag now" (release runbook is mechanical).

**ROADMAP fuel / demand-gated (unchanged):**
24. Live-monitor render proof (rides the switch).
25. Second-compositor live proof.
26. nixosTests-style VM test.
27. `packages.<sys>.offline-banner-shell` public passthru.
28. `nixosModules.example`.
29. Per-monitor namespace suffix.
30. Metrics endpoint (loopback state JSON) on consumer demand.
31. IPv6 probe leg revisit (v6-primary host trigger).
32. Upstream to nixpkgs.
33. Release automation (tag → release notes).
34. Launch-post posting (owner; pairs with the real-monitor proof).
35. CONTRIBUTING/SECURITY/CODEOWNERS (audience triggers).
36. Renovate-vs-dependabot final call (annoyance trigger).
37. Pre-commit treefmt hook.
38. CI aarch64 on a real arm runner.
39. Sound/notification hook (doctrine risk — default OFF if ever).
40. Optional context line in the banner (probe expressiveness theme).
41. `FileView` state writes (fewer processes; API verification needed).
42. Firewall for the stale-socket hygiene observed today (4 niri sockets, 3
    dead) — likely upstream niri cleanup behavior, watch only.
43. Investigate whether the displayless niri session should be reclaimed or
    reaped (see §g-2).
44. `.hyperframes/` policy check after the website session's churn settles.
45. Consider `trash-cli` tmpfs behavior documentation (worked on /run today;
    record that in lessons if it generalizes).

**Standing non-goals (re-listed so they stay visible):**
46. DNS-leg probe. 47. Multi-host probeHost. 48. ExecReload live-retune.
49. Banner flashing/sound by default (doctrine: static non-flashing yellow).
50. Machine-reflowing point-in-time reports (markdown is hand-formatted).

## g) Three questions I cannot answer myself

1. **Cut v0.1.1 before the SystemNix relock?** The journal-token change is a
   user-visible contract change sitting in `[Unreleased]` (my stated default,
   taken). But SystemNix's relock instruction now points at a moving HEAD
   (`a91a77a`); tagging v0.1.1 first would give the switch a frozen,
   changelogged target. Tag now, or relock HEAD and tag later?
2. **The displayless niri session (PID 5049)**: my recon says displayless by
   circumstance (you work over SSH; DP-1 connected but DRM-disabled; a healthy
   banner unit runs under it). Should that session be reclaimed (re-login to
   get the real-monitor proof for free), reaped, or left as the standing
   headless testbed?
3. **Website lockfile ownership**: `pnpm update` in website/ would address 20
   dependabot alerts, but that subtree has an active session. Is website/
   yours/another session's until further notice, or may any session run
   dependency updates there?

---

*Verified evidence anchors: render-smoke `4cff63a`; consumer `767728b`;
deflakes `cade264`/`39d51bf`/`8a14308`; dprint deletion `6d429aa` → zombie
`dabd06f` → re-execution staged this session; lessons `4f6dd31` (crush-config);
doc updates daemon-committed through `9c178b7`. Annotation specs drafted but
NOT applied (§b-1). Point-in-time snapshot; use docs-health ANNOTATE.*
