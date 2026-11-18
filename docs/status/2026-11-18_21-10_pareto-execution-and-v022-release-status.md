# Status — pareto plan execution (P1–P20) + the v0.2.2 release · 2026-11-18 evening

**Scope:** the 2026-11-18 14:11 pareto plan (`docs/planning/2026-11-18_14-11_…`), owner-approved ("NOW GET SHIT DONE"), executed end-to-end by this session in coordination with a parallel fleet-review session (claim-file protocol held all evening).

## a. The release (the 1%) — v0.2.2 is OUT

- **Tag `v0.2.2` → `a5c19ee`**, curated release live: <https://github.com/LarsArtmann/offline-banner/releases/tag/v0.2.2>. Tag-source verify: `nix flake check github:LarsArtmann/offline-banner/v0.2.2 --all-systems` → all checks passed; metadata locked rev matches the tag.
- **Runbook step 1b executed LIVE pre-tag** (its first real exercise, closing row 89's intent): `OFFLINE_BANNER_SMOKE_DEMO=1 nix run .#smoke` → `banner state=shown` journaled 20:37:33, state file landed in the ISOLATED `offline-banner-smoke` dir with `demo:true`, the live unit's heartbeat stayed 0 s old through the whole cycle (the shared-namespace hazard is dead in production use), transient stopped via busctl `StopUnit … "replace"`.
- **Release content**: dns answer-validation (behavior change, called out first in the notes + an upgrade aside on the website's how-it-works page), the smoke-transient crash trio + namespace isolation + the env-attrset fix, pid-unique temp stage, hyperframes 0.9.52 re-render (WCAG re-audit: 20/20 AA), starlight 0.43.1.
- Website changelog `## 0.2.2` deployed and FETCHED live (section present). CI green on the release candidate; one repair cycle mid-cut: the daemon swept the parallel session's status report carrying an unannotated §f item → docs battery red on CI → annotated done-at-submission (`c6a6cfe` carried it) → battery green → Checks green on `a5c19ee`.

## b. P1 smoke-isolation (done here, row 88 closed by the parallel session's sweep)

- The props rewrite renames every provisioned dir to `*-smoke` (Runtime/State/ReadWritePaths, cache home, ledger env), injects `OFFLINE_BANNER_STATE_DIR` (new QML seam, unset = byte-identical), and `RuntimeDirectoryPreserve=true` for the shared quickshell dir; sound env split into `props-sound.txt`, consumed only under `OFFLINE_BANNER_SMOKE_SOUND=1`.
- **Latent 0.2.1 bug found by the rewrite**: the props read `serviceConfig.Environment` — an attrset that never exists — so the transient silently ran on QML defaults (no hardened PATH, no cache home, no ledger env; the `%h` hole was never actually exercised by a smoke run). Now reads the real `environment` attrset.
- Gates: smoke-script namespace/sound/argv gates both directions, shell-content seam marker, a probe-transitions seam scenario proving the redirect END-TO-END on the real QML (redirected dir gets the state file, the default dir stays clean). All green x86_64 + binfmt aarch64.

## c. The owner-window one-commanders (the 4%)

- **ci-watch red path proven** (parallel session, row 90): dispatch run success + the red path executed locally under a `gh` shim (exits 1 with the annotation, master untouched).
- **DMS post-switch checklists** (rows 16 + 82): enable steps, widget-state expectations table, the stale-tell busctl recipe; plugin parity re-verified single-sourced (`consumerPath = "${offlineBanner}/contrib/offline-banner-waybar"`).
- **Sandbox posture** (row 54, parallel session): all three withheld candidates probe-evidenced; re-affirmed withheld.
- **Audibility** (row 91, parallel session): journal re-sweep verdict — quiet pw-play = clean success; failure would have printed; the class is dead with silent-by-default demos.

## d. Recurrence prevention & knowledge (the 20%)

- **Claim protocol ACTIVE** (row 87 agent-side done): first-day evidence recorded — two sessions split the list by claims with zero duplicate work; rc-guard one-liner in AGENTS; daemon-skip remains owner-side.
- **Proof-class audit in AGENTS** (new): every check classified EXECUTES / MIXED / STATIC-ANALYZE / GREP; verdict — no grep-only gate guards executable behavior (the smoke-props gap was the last one; closed this session).
- **D1 fresh numbers** (row 80): vm-smoke local rebuild 27.4 s (native KVM), CI tcg estimate ~2.5–5 min; aarch64 binfmt six-check suite 61.6 s. The decision is now priced, not feared.
- **Launch posts refreshed** (v0.2.1 legs/ladder story + release links + the v0.2.2 dns sentence ready).
- **Evening-window recipe in row 79** (exact commands + closure criteria). **D3 memo** (row 81): ACCEPT THE GAP, evidence-based — every local journal source rotates in at 2026-11-10; nothing exists to reconstruct. **D4 memo** (AGENTS): adopt a skip-only `.buildflow.yml` (coverage stops the zombie), file the fleet-wide skip upstream. **Multi-host probeHost memo** (ROADMAP theme 1): do-not-build verdict with the named trigger + the minimal honest step if it ever fires. **wlrctl recon** (row 34c): `zwlr_virtual_pointer_manager_v1` confirmed in niri's binary — click-dismiss harness is viable, recipe written. **ROADMAP themes 2–5 swept**: ledger-analytics struck partially-realized (website cookbook).
- **Fleet lessons committed** to crush-config (`b40bb36`): busctl substitute, absolute-path discipline, Nix heredoc quoting; referenced from AGENTS hard-rules.

## e. Coordination facts worth keeping

- The claim file (`docs/status/.session-claim`, gitignored) worked as designed: claims were honored, heartbeats refreshed, the stale-2h rule voided the ended session's claims cleanly at release time.
- The daemon swept work into ~10 `chore: auto-commit` commits across both sessions; per the AGENTS tolerance the tree state was treated as truth and messages document the sweeps; one mid-release sweep required the battery-repair cycle above.

## f. Open items routed (none unharvested)

1. **D1 owner verdict** — fresh numbers in row 80; owner decides blocking vs advisory.
2. **D3/D4 verdicts** — owner-ready draft text in row 81 / AGENTS.
3. **Owner windows** — DMS enable + stale-tell (rows 16/82), sound audition (row 22), evening sweep (row 79 recipe), posting the launch drafts (row 19/T19), reboot/second-output/click-dismiss one-sitters (row 34 recipes).
4. **Upstream BuildFlow skip-feature** — file when convenient (D4 follow-up).
5. **daemon claim-awareness** — owner-side config (row 87 tail).

## g. Verification state at close

- master `84a7a2c` pushed; CI green through `a5c19ee` (Checks) and `15eac36` (Website); row-92 closure commit awaiting its Checks run (docs-only).
- Local at close: `nix flake check --all-systems` green, docs battery green, website gates green.
- Live unit on evo-x2: active, heartbeat fresh, untouched through the smoke cycle and the release.
