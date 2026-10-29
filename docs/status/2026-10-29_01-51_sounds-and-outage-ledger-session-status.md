<!-- Status report for the 2026-10-28/29 sounds + outage-ledger session. Point-in-time
     snapshot; open items harvested forward into TODO_LIST.md / ROADMAP.md. -->

# Status: sounds + persistent outage ledger (2026-10-28 → 10-29, 01:51)

Session scope: owner asked for (1) "more sounds, be creative!" and (2) a persistent
offline log ("from when to when"). Both shipped into `module.nix`, gated, documented,
and verified — including a real audible end-to-end run. Everything below is scoped to
THIS session only.

Headline evidence: `nix flake check --all-systems` green (all 7 gates, x86_64 native +
aarch64 emulated, 2026-10-29 ~01:40); real-QML run played chimes through the host
PipeWire and appended a real ledger entry
`{"from":1793233836,"to":1793233838,"durationSec":2,"reasons":["net"],"probeFailures":4}`.

## a) FULLY DONE

1. **Sound cues, 3 synthesized themes + none** — `chime` (soft sine droop/sparkle, default),
   `droplet` (pitch-bent plips), `retro` (8-bit square). WAVs synthesized at build time by
   an inline stdlib-Python generator inside module.nix (no assets, no fetch, no new runtime
   deps beyond pipewire-in-PATH). Doctrine-faithful: ONE cue per outage (never per probe),
   lower pitch for link loss, ascending sparkle on recovery, quiet tick on dismiss.
   Evidence: `shell-content` WAV gate (3×4 matrix, valid sub-second 44.1 kHz mono) green;
   all 12 files peak-normalized (spot-checked numerically).
2. **Sound options + env contract** — `soundTheme` (enum, default `chime`), `soundVolume`
   (0–100, default 60); unit env `OFFLINE_BANNER_SOUND_THEME/SOUND_VOLUME/SOUNDS` +
   internal test seam `OFFLINE_BANNER_SOUND_CMD`. Bare runs (env unset) are silent by
   design — machine-asserted via the demo-instance silence assert.
3. **Persistent outage ledger** — one JSONL entry per COMPLETED outage
   (`from`/`to`/`durationSec`/`reasons`/`probeFailures`) appended to
   `%h/.local/state/offline-banner/history.jsonl` (default; `enableHistory`, `historyPath`
   options). Sub-debounce blips, still-open outages, and demo mode never write. The parent
   dir is the unit's ONLY writable home path (`%h` ReadWritePaths hole). Journal token
   `outage ended from=… to=… duration=…s reasons=…`; state file gained `since`.
4. **Real playback + real append proven** — end-to-end run 2026-10-28 ~23:50: real store
   QML in headless sway, real `pw-play` through the host PipeWire (offline-net droop on
   show, recover sparkle on recovery — audible), real history entry (JSON above). Opt-out
   config eval-verified (theme `none` + history `false` → env vars, pipewire PATH, and
   the home hole all absent from the rendered unit).
5. **Checks extended, all green both systems** — `module-contract` (+4 env vars, pipewire
   PATH, `%h` hole, exactly-2 restartTriggers), `shell-content` (+ sound/history QML
   markers + WAV matrix gate), `probe-transitions` (+ ledger jq-asserts, `since`
   set/cleared, cue-per-transition incl. negatives: no re-sound on mid-outage reason
   switch, open outage no-entry, demo silent/no-write). aarch64 emulated runs of
   probe-transitions + render-smoke passed (the historically flaky pair).
6. **Docs** — README (behavior bullets, 11-option table, tuning + observability,
   comparison rows), FEATURES (2 new rows with honest 🟡 status + evidence, 11-option
   count), CHANGELOG [Unreleased] Added, TODO_LIST (3 new rows), AGENTS.md (env-surface
   extension, checks descriptions, runbook inertness note, NEW hard rule: never embed
   `${`-style or literal `''` in inlined scripts — codified from this session's own-goal).
7. **Cross-project lesson committed to crush-config repo** — the Nix indented-string
   silent-corruption gotcha (`references/lessons.md`, unpushed).

## b) PARTIALLY DONE

1. **Live proof under the real hardened sandbox** — works: everything through the seams +
   the un-sandboxed real run. Open: pw-play FROM the unit (pipewire socket under
   ProtectSystem=strict — expected to behave like the proven Wayland connect) and the
   `%h` write hole receiving an append on a real outage. Both ride the SystemNix switch.
   Blocker: monitor-on live session. Effort: S (observational, next session/deploy).
   [TODO_LIST watch row exists]
2. **Sound aesthetic QA** — 2 of 12 cues heard by a human (chime-offline-net,
   chime-recover). droplet×4, retro×4, chime-offline-link, chime-dismiss: validated as
   WAVs but UNHEARD. Frequencies/envelopes were chosen by reasoning. Effort: S (play all
   12, tune).
3. **Website + marketing surfaces** — website docs pages still describe the 7-option
   module; launch-post drafts don't mention sounds/history. Public site goes stale the
   moment this ships. Effort: M (website update + rebuild + deploy).
4. **Dismiss cue machine-verified** — no pointer harness (pre-existing T18 gap); the
   `dismiss` cue path is code-symmetric but never fired by any test. Effort: M (virtual
   pointer harness) — also closes the pre-existing click-dismiss row.
5. **Git hygiene under the auto-daemon** — session work sits inside `chore: auto-commit`
   commits (8c178e0, 7572524, likely more since); the AGENTS-mandated reset-soft/recommit
   dance was NOT performed (harness forbids commits without an explicit ask). Working
   tree had uncommitted doc edits at session end. Effort: S (on owner instruction).

## c) NOT STARTED

1. **Website options/observability sync** — queued as TODO `[ready]`; deliberately not
   started (scope call: module + gates first). Still wanted; blocks a clean v0.2.0
   release story.
2. **Waybar consumer `since` support** ("offline for 4m") — natural follow-up, not asked,
   not started. Priority: nice-to-have.
3. **v0.2.0 release cut** — CHANGELOG [Unreleased] is fat and ready; tag + release
   runbook exists. Not started (owner-gated; see question g-1).
4. **History analytics/consumer tooling** (contrib stats script, waybar tail widget) —
   not started, arguably ROADMAP fuel.

## d) TOTALLY FUCKED UP!

Nothing in the FINAL state is broken (all gates green both systems). The honesty section
is therefore the transient damage log — three self-inflicted wounds in one edit area:

1. **Environment-attrset restructure dangled `PATH` outside the attrset** — overlapping
   multiedits instead of one clean rewrite; caught by the immediate syntax eval
   (`unexpected ';', expecting end of file`). Cost: 1 eval round. Root cause: editing a
   block whose old_string spanned a boundary I then re-created differently.
2. **Shell `${n:-0}` inside the Nix `''` check script was SILENTLY corrupted** to
   `n:-0` — Nix produced no eval error; the check failed at runtime with
   `[: n:-0: integer expected`. Worst failure class: silent. Cost: 1 failed check run
   (the feature itself was green — sounds.log showed the correct cues). Root cause: I
   violated an AGENTS hard rule that was in my context the whole session — I applied the
   no-`${`-in-QML rule but wrote a NEW shell snippet in flake.nix without re-applying it.
3. **The fix comment contained a literal `''`** ("inside this Nix '' string") which
   TERMINATED the indented string → parse error; the re-fix comment contained `${...}`
   — same trap again. Cost: 2 more edit/eval rounds. Three consecutive own-goals in ~10
   lines. Salvage: rule codified in AGENTS.md + crush-config lessons (so the NEXT agent
   in ANY LarsArtmann Nix repo gets it), and POSIX-safe guard style (`|| true`, `[ -z ]`)
   used in the final code.

Also honestly noted: the end-to-end run wrote the REAL runtime-dir state file (recovered
before kill, so no lying state was left — but a mid-outage kill would have left
`active:true` for the waybar consumer until the real unit overwrote it).

## e) WHAT WE SHOULD IMPROVE

1. **Embedded-script edit discipline** — any new shell/QML/JS line inside a Nix `''`
   string should get a mental (or grepped) `${`/`''` audit BEFORE building, not after a
   runtime corruption. Fix: the codified AGENTS rule; candidate: a treefmt/statix-style
   grep guard in flake checks (`rg -n '\${' module.nix flake.nix` allow-list review).
2. **fmt-before-gates ordering** — I built checks from pre-fmt source, then `nix fmt`,
   then re-ran the full check. Harmless here (string contents proved identical) but the
   discipline should be fmt-first.
3. **Daemon-commit hygiene** — the AGENTS reset-soft dance for swept work was skipped
   (commit-averse harness reading). Clarify in AGENTS: the dance IS owner-sanctioned even
   mid-session, or add it to the session-end checklist.
4. **Negative-config gates** — module-contract asserts the enabled-config positives; the
   `soundTheme="none"` + `enableHistory=false` opt-out is eval-verified once in-session
   but has no permanent check. A second eval fixture in module-contract would pin it.
   Same for the new historyPath absolute assertion (never negative-tested).
5. **Sound QA is un Automatable** — WAV gates validate structure, not taste. Add a tiny
   `scripts/play-sounds.sh` (loop `pw-play` over the store dir) so the owner can audition
   all 12 cues in 15 s after any retune.
6. **FEATURES audit-header drift** — the header lists audit dates (last 2026-10-17); this
   session's rows are new but the header wasn't dated. (Fixed during report harvest.)
7. **Split brains found (small, accepted/triaged)**: `soundVolume` default 60 lives in
   both the Nix option and the QML env fallback (same accepted pattern as intervalMs —
   drift risk if the option default changes); dprint.json vs the documented drop decision
   (see below — SECOND resurrection); FEATURES header vs content. No ghost systems found
   — every new capability is wired (sounds → unit env+PATH; ledger → env+hole+checks).

## f) Next tasks (harvested; TODO-grade first, then ROADMAP fuel)

TODO-grade (bounded):

1. Live sandbox proof: pw-play + %h append on a real outage (rides SystemNix switch) —
   High / S / Quality. [row exists]
2. Website options/observability sync (4 new options, sounds/history sections) —
   High / M / Documentation. [row exists]
3. dprint.json SECOND resurrection decision (re-drop vs adopt `.buildflow.yml`) —
   Medium / S / Cleanup. [row exists, updated to "second"]
4. Audition all 12 cues (`scripts/play-sounds.sh` helper) + tune frequencies —
   Medium / S / Feature.
5. v0.2.0 release cut (CHANGELOG fold + tag + release) after g-1 answered —
   High / S / Release.
6. Squash daemon-swept auto-commits into one real-message commit (owner-gated) —
   Medium / S / Cleanup.
7. Waybar consumer: "offline for Nm" from `state.since` — Medium / S / Feature.
8. probe-transitions: trip one outage on reason=link from a clean start so the
   offline-LINK cue is positively asserted (today only negatively) — Low / M / Quality.
9. module-contract: negative fixture — theme "none" + history false must DROP
   sound env/pipewire/hole from the unit; relative historyPath must assert —
   Medium / M / Quality.
10. Virtual-pointer (or first-live-outage) proof of click-dismiss → closes the dismiss
    cue AND the pre-existing T18 rows — Medium / M / Quality.
11. README: one line on PipeWire requirement (no pw-play → one journal line per outage,
    banner unaffected) — Low / S / Documentation.
12. README Observability: note that crash-lost ledger entries are reconstructible from
    the `outage ended` journal token — Low / S / Documentation.
13. Launch-post drafts: mention sounds/history (one sentence each) — Low / S / Marketing.
14. Revisit withheld sandbox options (SystemCallFilter etc.) after item 1 lands —
    Low / M / Quality. [pre-existing theme]
15. docs/status index row for this report (done during harvest) — n/a / S.

ROADMAP fuel (raw ideas, not refined):

16. More themes (birds, synthwave, "subtle" ultra-quiet set) + per-event theme override
    (`soundTheme` per event, e.g. silent dismiss + loud recover).
17. DND/quiet-hours awareness (respect a presence/mode file).
18. "Still offline" reminder cue every N minutes for long outages (doctrine risk —
    warning-not-page tension; decide first).
19. Custom theme from a user file (drop wavs in a dir, point an option at it).
20. contrib stats script: `offline-banner-stats` — total/longest outage per week/month
    off history.jsonl (jq one-liners documented today; a script could chart).
21. Waybar history widget: last outage duration + total today.
22. Ledger retention policy (size cap / rotation) — owner taste (see g-2).
23. Sound preview in `nix run` form (`nix run github:…#audition`?) — needs a packages
    output; also unlocks direct sounds-drv consumption.
24. History `open`/`close` paired-event format as an ALTERNATIVE ledger (crash-proof)
    — decision item, current format documented as accepted.
25. v6 probe leg, multi-host probeHost, DNS-leg probe (pre-existing ROADMAP themes —
    unchanged, listed for completeness).

## g) Questions I cannot answer myself

1. **Ship sounds ON by default?** `soundTheme` defaults to `chime` — every public-flake
   consumer going past this commit gets audible cues on their next outage without opting
   in. I chose ON because you asked for sounds (you are the primary user), but the
   polite-public default is `none` + you set `chime` in SystemNix. Keep `chime` or flip
   to `none` before the v0.2.0 tag? (Blocks the release cut, item f-5.)
2. **Ledger retention**: `history.jsonl` appends forever (one tiny line per outage —
   years of outages is still kilobytes). Append-forever, or do you want a cap/rotation
   policy (e.g. keep last 1000 entries)? Pure owner taste; I cannot derive it.
3. **Theme character judgment**: I can verify structure, not taste — and 10 of 12 cues
   have never been heard by a human. Run
   `for f in $(ls -d /nix/store/*-offline-banner-sounds)/\*.wav; do echo $f; pw-play $f; done`
   and tell me which themes/frequencies to tune (I'll re-synthesize in minutes).

— Report ends. Waiting for instructions.
