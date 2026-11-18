# 2026-11-18 ~22:15-23:0x — whole-TODO-list execution: D1, D3, click-dismiss proof, row verdicts (third evening session)

Third session on the 2026-11-18 "do the whole TODO list" directive (after the 21:54 todo-execution session and the pareto v0.2.2-release session). This session coordinated with both via the claim file, verified the release externally, then executed every remaining machine-actionable row.

## a. Starting state (verified, not assumed)

- v0.2.2 ALREADY CUT by the pareto session (row 92 `[x]`, tag → `a5c19ee`, release published 21:30:57Z) — verified externally this session: `gh release view v0.2.2`, `git ls-remote` tags resolve `v0.2.2^{}` → a5c19ee. NOT redone (the claim file showed pareto's fresh claim; the row was already honest).
- Everything pushed: master in sync at a5c19ee at session start; HEAD CI (44401832914) green; the 21:25 red (docs battery, unannotated §f item) already repaired by a5c19ee.

## b. D1 decided and executed (row 80)

- **PROMOTED, BLOCKING**: `checks.x86_64-linux.vm-smoke` (flake.nix, commit `3c74d56`, re-split from a daemon sweep). x86_64-only via `optionalAttrs` — a VM inside binfmt aarch64 emulation is quadratic and proves nothing the x86_64 boot doesn't. The then-quoted ~2.5-5 min tcg tax estimate was FALSIFIED hours later by the first CI runs: **~33 s** measured (see §g); earlier texts (CHANGELOG/AGENTS/flake comment) carried the estimate as fact and were corrected in the 23-40 self-review pass. Local verify: `nix eval` shows all 12 x86_64 checks (vm-smoke present, aarch64 has 11), VM builds green (cached ~7 s post-first-run), full `nix flake check` green.
- First CI run carrying the gate: run 44406334307 (on `25e4839`, which carried the flake change via a daemon sweep inside pareto's pushed range — junk message, pushed, not rewritable).

## c. D3 decided (row 81)

- **ACCEPT THE GAP** — the owner-ready draft decision became the executed verdict: no code exists to change; the 2026-10-16→11-05 window is unrecoverable on-host (journal bounds re-checked by the prior session), `backfilled:true` schema complexity rejected, cause dead since ad6cac3.

## d. Row 34 leg (c): click-dismiss machine proof — CLOSED with a shipped harness

- **`scripts/click-dismiss-proof.sh` + `scripts/demo/band-count.py`** (shellcheck/shfmt-gated via `shell-scripts`). The proof, live on evo-x2 (real DP-1, 4K): baseline band **96 px** → demo shown (state `active:true`, band **233260 px** — verified BEFORE any click) → wlrctl virtual-pointer click at logical (1536, 64) (corner-reset + relative move; wlrctl has no absolute motion) → state `.active` false within 100 ms polls → band settled **3505 px** (poll-to-threshold: the strip slides up animatedly, state flips before pixels) → live unit state byte-identical across the run → transient stopped via busctl. QML journals `banner state=dismissed rearm=next_clean_probe` (runs at 22:42, 22:45, 22:50).
- **Three harness bugs found and fixed fail-closed** (each earned by a real run):
  1. grim's STDOUT mode silently produces ZERO bytes in some contexts — explicit output path is mandatory. First run clicked on empty pixel evidence (state-file legs still passed — the dismiss mechanism was real); the harness now aborts before clicking on ANY unverified capture (non-numeric/failed counts die).
  2. `busctl GetUnit ss "name"` — signature took two `s` for one argument → "Too few parameters" → the preexisting-transient precondition was a silent no-op. Fixed to one `s`.
  3. Single-shot post-dismiss capture landed mid-animation → transition-poll the band down instead (the repo's own CI-timing doctrine applied to a live tool).

## e. Row verdicts recorded

- Row 83 (TS7): fresh registry check tonight — `@astrojs/check@latest` peers still `^5.0.0 || ^6.0.0`, `typescript@latest` 7.0.2 → signal not fired, stays `[watch]`.
- Row 87: researched to the hook point — PMA `pma-daemon/committer/committer.go:180` `ShouldCommit` is the patch site (~20 lines: fresh `<repo>/docs/status/.session-claim` heartbeat < 2 h ⇒ skip); recipe attached to the row. NOT implemented from here: different repo, live fleet daemon, activation owner-side regardless.
- Rows 16/22/79/82: genuinely owner-only (GUI plugin enable post-switch, ears on 12 cues / a real outage, reboot/second monitor, the switch itself) — recipes already in the rows; no fake progress made.

## f. Docs swept

- TODO_LIST rows 80/81/34/87/83 updated with evidence + verdicts; CHANGELOG `[Unreleased]` gains the blocking VM gate + the harness; AGENTS gains the D1 paragraph, the updated `shell-scripts` surface list (five files, honest roles), and the live-evidence click-dismiss block. Docs edits committed as `7a4df29` after re-splitting a daemon sweep.

## g. CI on the pushed commit — the real sequence (updated 23:1x)

- Run 44407389408 on `7a4df29` FAILED — but NOT on the product: `nix-check` passed **2m27s with the blocking VM gate inside it** (log: `evaluating 'checks.x86_64-linux.vm-smoke'… ✅` — the tcg boot cost **~33 s**, 5-10x under the row-80 estimate; the earlier gate-carrying run 44406334307 was green in 6m50s, wall-clock ≈ +4 s over the pre-gate run because check derivations build in parallel). The red step was the **docs-freshness audit-all**: 2 unharvested open items, BOTH from old reports — the 13-26 report's "D1 decision" item (resolved by this session: struck with the verdict) and the 11-05 hardening report's "lessons.md emulated-arm ritual" item (the ritual has proven itself; lesson enshrined in crush-config `references/lessons.md`, commit `a7c651e`; item struck done-at).
- Battery re-run locally after the strikes: green across all five gates. Repair commit pushed after `7a4df29`; final verdict recorded in the line below once the run lands.

**Verdict (done at submission, carried by this commit): docs battery green locally across all five gates after the strikes; the product gates were already CI-proven on `7a4df29` (nix-check 2m27s incl. `checks.x86_64-linux.vm-smoke` ✅, tcg boot ~33 s — run 44407389408's log, the only red step being the since-fixed docs battery). D1's real CI cost: ~33 s, not the feared minutes.** The whole machine-actionable TODO list is executed, verified, and pushed; what remains is owner-only.
