# Status Report — nix* skills review pass on offline-banner

**Generated:** 2026-10-16 23:28 CEST · **Scope:** this session only (the "all nix\* skills — READ, UNDERSTAND, RESEARCH, REFLECT, execute, verify" run). No unrelated research performed, per instruction.
**HEAD:** `580f741` (auto-daemon commit of the session's 5 files) + uncommitted `AGENTS.md` Checks-line edit · **CI:** 🔴 RED on master — root cause verified, see (d)1.

**Skills loaded & applied this session:** `nix-review` (checklist applied to every `.nix` file), `nix-private-go-repos` (assessed → **N/A**, no Go/vendor), `buildflow` (assessed → **not covered**, no `.buildflow.yml`; used the project's own `nix fmt` / `nix flake check` per AGENTS.md), `status-report` + `brutal-self-review` (this report; the self-review is folded into §d/§e per the single-file instruction — no separate `docs/reviews/` file was created).

**Format note:** the status-report skill is HTML-canonical; you explicitly demanded `.md` at this path, so `.md` it is — flagged as a one-off override, not propagated into the skill.

---

## a) FULLY DONE

| # | What | Evidence | Files |
|---|------|----------|-------|
| a1 | Full nix-review checklist pass over both `.nix` files (all ~90 checklist items) + applicability assessment of the other two nix skills | Findings F1–F4 below; no other checklist violations found | — |
| a2 | **systemd sandbox hardening** on the user unit: `ProtectSystem=strict`, `ProtectHome=read-only`, `PrivateTmp`, `RestrictAddressFamilies=[unix,inet,inet6,netlink]`, `RestrictNamespaces`, `LockPersonality`, `RestrictRealtime`, `RestrictSUIDSGID`, `ProtectClock/Hostname/KernelLogs/KernelModules/KernelTunables/ControlGroups`, `ProtectProc=invisible`, `SystemCallArchitectures=native` — each block carries a doctrine-style rationale comment | `module.nix:310+`, committed in `580f741` | module.nix |
| a3 | **Deliberate-absence rationale documented**: `NoNewPrivileges` withheld (it ignores iputils' `cap_net_raw` file capability → every ping silently fails → permanent "net" state), `PrivateDevices` withheld (GPU `/dev/dri`), `MemoryDenyWriteExecute` withheld (QML JIT), `SystemCallFilter` withheld — rendering is not CI-testable | comment block at `module.nix` serviceConfig | module.nix |
| a4 | **Contract check extended**: `module-contract` now asserts the sandbox is present in the unit text (3 markers) AND `NoNewPrivileges` stays absent — a "helpful" future edit fails loudly with the reason | `flake.nix` module-contract; assertions pass | flake.nix |
| a5 | **flake.nix cleanup**: `treefmt-nix` input now `follows = "nixpkgs"` (lock dedup, −17 lines); `getPlatform` indirection removed; `treefmtEval`/`checks`/`formatter` keyed by system directly | diff in `580f741`; `nix fmt` → 0 changed | flake.nix, flake.lock |
| a6 | **Docs updated**: CHANGELOG "Security" section; TODO_LIST new `[watch]` debt entry (hardened-unit live verification); AGENTS.md Checks line mentions sandbox contract | `580f741` + working tree | CHANGELOG.md, TODO_LIST.md, AGENTS.md |
| a7 | **Verification loop**: `nix fmt` clean, `nix flake check` → `all checks passed!` — run twice (after code edits and after doc edits) | session tool output, x86_64-linux | — |

## b) PARTIALLY DONE

| # | Item | Works | Open | Blocker | Effort |
|---|------|-------|------|---------|--------|
| b1 | **Hardened unit** | Eval-verified: assertions prove the unit text carries the sandbox | **Zero runtime verification** — Quickshell may fail to render or ping under the sandbox; a failure mode is *silent banner absence*, the project's worst case per doctrine | Needs a live Wayland session (CI can't do it by design) | S–M |
| b2 | **Multi-system coverage** | Module evaluates for `aarch64-linux`; `checks` defined for both systems | Local check omits aarch64 ("incompatible systems" warning); CI never reached that point (workflow dead, see d1); formatting check for aarch64 needs emulation on x86_64 runners | Decision: binfmt in CI vs drop the system | S–M |
| b3 | **"Verified" claims** | Every green claim in this session is real — locally, on x86_64 | Nothing is CI-verified (see d1/d2) | d1 fix | S |

## c) NOT STARTED

All carried in `TODO_LIST.md`, untouched this session (I stayed scoped to the nix review):

- **state-transition observability** (journal lines on show/hide + `offline_banner_active` gauge) — `[ready]`, never started
- **VM/negative test** (`OFFLINE_BANNER_SYSROOT` + probe injection; link/net/ok/debounce assertions) — `[ready]`
- **IPv4-only probe blind spot** (v6-up/v4-down false "offline") — `[ready]`, needs v6 leg or a documented tradeoff
- **demo mode** (`OFFLINE_BANNER_DEMO=1`) — `[ready]`
- **claim cleanup** ("DMS plugins cannot render layer-shell" is reasoned, never tested; iface-list cross-ref to SystemNix dual-wan QML) — `[ready]`
- **live-verification debts**: reboot auto-start, multi-monitor proof, click-to-dismiss — `[watch]`
- **LICENSE decision** — `[blocked:user]`
- **SystemNix cutover** — unblocked (repo pushed 2026-10-16) but not executed
- **origin-host live tunables** — `[watch]`

## d) TOTALLY FUCKED UP

1. **CI has NEVER been green — verified root cause.** `.github/workflows/checks.yml:16` pins `DeterminateSystems/nix-installer-action@3138316df39ed29be24236d7ffc686fa525866aa`; GitHub API returns **422 "No commit found for SHA"** for it in that repo. Both runs on master failed in ~5–6 s at action resolution — no nix check has ever executed. Severity: blocks all CI signal, and the SystemNix cutover has no green gate to lean on. Root cause: an **unverified action pin written at project creation** (the SHA looks plausible next to its `# v23` comment — it is fabricated or mis-copied). Mitigation: re-pin to a real release commit (resolvable via `gh api` in minutes) — one line. Note: this predates my session (I never touched the workflow) — and my own session's commits rode in on that red pipeline.
2. **My "all checks passed" is weaker than it sounds.** True locally, x86_64 only; the all-systems CI gate that would make it mean something is dead (d1). Honest downgrade: *verified on one system, zero CI verification.*
3. **I shipped unverifiable config to a live-deployed surface.** The sandbox bundle landed based on reasoning, not a run — by this project's own fail-visible doctrine, a sandbox break = banner silently absent. Debt is recorded (TODO_LIST b1) and the withheld list is documented, but "documented risk" ≠ "verified safe". The live smoke test should gate the SystemNix cutover.
4. **I noticed the aarch64 warning during verification and deferred it** instead of closing the loop (fix / file / document). It is now at least documented here and in (f)3 — but in-session that was a drop.

## e) WHAT WE SHOULD IMPROVE

1. **Verify-before-pin process gap** — the fabricated action SHA is exactly the failure class `verify-external-claims` exists for. Every pin should be resolved/validated at write-time (`gh api repos/.../commits/<sha>`), not copied from memory.
2. **Two formatter arbiters (split brain).** AGENTS.md says `nix fmt` (treefmt: nixfmt+statix) is "the only style arbiter", yet `dprint.json` (markdown/json/yaml/dockerfile) sits in the root with nothing in-repo invoking it. Decide: wire dprint into treefmt, or drop it, or document it as BuildFlow-reserved.
3. **BuildFlow provenance confusion.** `.gitignore` carries a buildflow-managed block ("auto-managed by buildflow") while the project has no `.buildflow.yml` — either cover the project or trim the block to stop lying about provenance.
4. **Contract granularity.** `sandboxInUnit` asserts 3 markers, not all ~15 sandbox lines — a refactor could silently drop `ProtectProc` etc. Assert every line; it's one list.
5. **README Quickstart leaks a second nixpkgs to consumers** — no `inputs.offline-banner.inputs.nixpkgs.follows = "nixpkgs";` in the snippet. One line of docs saves every consumer a duplicated lock entry.
6. **No unit-syntax gate.** A cheap check could write `unit.text` to `$out` and run `systemd-analyze verify` (needs a feasibility spike in the sandbox) — would have caught pin-class typos in serviceConfig too.
7. **Behavior is 0% tested.** The module is contract-checked only; the QML (debounce, dismiss, caption) has no test of any kind. The planned VM test is the fix; nothing cheaper meaningfully covers layer-shell rendering.
8. **Channel intent undocumented.** flake pins `nixpkgs-unstable`; the nix-review convention prefers `nixos-unstable` for Lars projects, and SystemNix's channel is unknown from this session. Decide and document the consumer-follows policy.

## f) Up to 50 things to get done next

> Brainstorm ranked by impact, per your "up to 50" — a larger N is roadmap fuel, not a commitment list. HARVEST-ready: items 1–14 belong in `TODO_LIST.md`, the rest route to `ROADMAP.md` or die deliberately. (I did **not** write them into TODO_LIST yet — you said "wait for instructions", so harvest runs on your go.)

| # | Task | Impact | Effort | Category |
|---|------|--------|--------|----------|
| 1 | Fix the `nix-installer-action` pin: resolve the real commit SHA for the intended version via `gh api` and re-pin | Critical | S | Bug |
| 2 | Push/re-run CI until master is green; watch the first real `nix flake check --all-systems` execution | Critical | S | Bug |
| 3 | Decide aarch64 strategy: QEMU/binfmt in CI vs. drop `aarch64-linux` from `systems` (is there any aarch64 NixOS host?) | High | S–M | Decision |
| 4 | Live smoke test of the hardened unit: `systemd-run --user` with the sandbox properties + standalone `quickshell -p` recipe; confirm render + ping + click-dismiss | High | S–M | Verification |
| 5 | `systemd-analyze verify` the generated unit text locally (one-off now; automate next) | High | S | Verification |
| 6 | Gate the SystemNix cutover on #4 passing (cutover: flake input, relock, thin-wrapper, parity verify, delete in-tree module) | Critical | M–L | Feature |
| 7 | Add `permissions: contents: read` (least privilege) to the workflow | Medium | S | Quality |
| 8 | Extend `sandboxInUnit` contract assertion to every sandbox option line | Medium | S | Quality |
| 9 | One-time `systemd-analyze verify` as a flake check (after feasibility spike) | Medium | M | Quality |
| 10 | README Quickstart: add the consumer `follows` line to prevent a second nixpkgs in consumer locks | Medium | S | Documentation |
| 11 | Decide dprint.json fate: wire into treefmt vs drop vs document as BuildFlow-reserved; reconcile AGENTS.md "only style arbiter" claim | Medium | S | Cleanup |
| 12 | Decide BuildFlow coverage: add `.buildflow.yml` or remove the managed `.gitignore` block | Medium | S | Cleanup |
| 13 | Resolve nixpkgs channel intent (`nixpkgs-unstable` vs `nixos-unstable`) and document the consumer-follows policy | Medium | S | Decision |
| 14 | Harvest this report's (f) into `TODO_LIST.md`/`ROADMAP.md` (docs-health HARVEST) | High | S | Process |
| 15 | Tag `v0.1.0` + GitHub Release (CHANGELOG says "versioning waits for the first tag") | Medium | S | Release |
| 16 | Branch protection on master: require the Checks workflow once green | Medium | S | Quality |
| 17 | Pin `actions/checkout` + `nix-installer-action` updates via dependabot/renovate (SHA-pinned updates, no drift) | Medium | S | Quality |
| 18 | LICENSE file once the owner decision lands (see g3) | Medium | S | Cleanup |
| 19 | State-transition observability: journal line on show/hide + `offline_banner_active` gauge (TODO §Quality) | High | M | Feature |
| 20 | VM/negative test: `OFFLINE_BANNER_SYSROOT` + probe injection; assert link/net/ok/debounce transitions | High | L | Test |
| 21 | IPv6 leg for the probe, or document the v4-only tradeoff in the option description | High | S–M | Feature |
| 22 | `OFFLINE_BANNER_DEMO=1` force-show mode; retire the unroutable-IP drop-in hack | Medium | S | Feature |
| 23 | Verify or soften the "DMS plugins cannot render layer-shell surfaces" claim (module header + README) | Medium | S | Documentation |
| 24 | Add cross-reference comment to SystemNix's dual-wan QML copy of the iface-exclude list | Low | S | Cleanup |
| 25 | Machine-verify click-to-dismiss (virtual-pointer harness or first live outage) | Medium | M | Test |
| 26 | Prove multi-monitor behavior (only DP-1 proven on the origin host) | Medium | S–M | Test |
| 27 | Prove reboot/re-login auto-start via `graphical-session.target` | Medium | S | Test |
| 28 | After live sandbox verification: reconsider withheld options (`SystemCallFilter=@system-service`) with evidence | Low | M | Verification |
| 29 | Confirm on live that `ProtectSystem=strict` yields only benign Qt cache-write warnings | Medium | S | Verification |
| 30 | Measure real Quickshell RSS on live; re-justify or adjust `MemoryMax=256M` | Low | S | Verification |
| 31 | Add FEATURES.md (DONE / PARTIALLY DONE / PLANNED / WORTH CONSIDERING) | Medium | S | Documentation |
| 32 | README: add hardened-unit bullet (it's a selling point) | Low | S | Documentation |
| 33 | README/AGENTS: name `module-contract` as the env-contract source of truth | Low | S | Documentation |
| 34 | Add CI status badge to README once #2 is green | Low | S | Documentation |
| 35 | Set repo description/topics on the GitHub remote (`nixos`, `quickshell`, `wayland`, `layer-shell`) | Low | S | Documentation |
| 36 | Post-cutover: set `layerNamespace = "systemnix:offline-banner"` in SystemNix for live parity (per CHANGELOG note) | Medium | S | Feature |
| 37 | Capture a demo GIF/screenshot of the banner for README (visual product, zero visuals) | Low | M | Documentation |
| 38 | `failuresToShow` sanity bound (assert reasonable upper limit) | Low | S | Quality |
| 39 | Optional DNS-leg probe (opt-in, default off — DNS must not gate the banner by default) | Low | M | Feature |
| 40 | Multi-host `probeHost` semantics (any-success vs all-fail) — decision first, code second | Low | M | Feature |
| 41 | Consider journal-based `console.log`/stderr routing for the QML (feeds #19) | Medium | S | Feature |
| 42 | Annotate prior status reports if any exist in `docs/status/` (this is the first) | Low | S | Documentation |
| 43 | Add actionlint/zizmor to CI (workflow lint + security) | Low | S | Quality |
| 44 | `persist-credentials: false` on actions/checkout (token hygiene) | Low | S | Quality |
| 45 | Evaluate `systemd-analyze security` score of the unit on live; record the exposure rating in AGENTS.md | Low | S | Verification |
| 46 | Assert in checks that `restartTriggers` still references the store QML (rename drift) | Low | S | Quality |
| 47 | Consider `ExecReload` / `systemctl --user reload` story or explicitly document restart-only tuning | Low | S | Documentation |
| 48 | Add `optionDoc` render check (nixos-option manual) or accept descriptions-only docs — decide | Low | S | Documentation |
| 49 | Update AGENTS.md Consumers section after cutover completes (remove "queued" state) | Low | S | Documentation |
| 50 | Post-cutover cleanup: retire SystemNix in-tree module + its status-report references | Medium | S | Cleanup |

## g) Questions only you can answer

1. **Sandbox risk gate:** do you accept the hardened unit going into the SystemNix cutover eval-only-verified, or should the cutover stay gated on a live smoke test (I can run the `systemd-run --user` + `quickshell -p` recipe on evo-x2 on your go)? I can't decide your risk tolerance for a live desktop where failure mode = silently absent banner.
2. **aarch64:** do any of your NixOS hosts actually run `aarch64-linux`? (Answer determines #3: drop the system from `systems` vs. add QEMU emulation to CI. The host inventory lives in SystemNix, which you scoped me out of this session — say the word and I'll check there instead.)
3. **LICENSE:** GPLv3 like sibling `niri-session-manager`, MIT/Apache, or proprietary-for-now? The TODO marks it `[blocked:user]` and 15+ downstream items (release, cutover polish) don't care, but public repo + no license = default "no rights" for anyone who stumbles on it.

---

*Point-in-time snapshot — will go stale. Section (f) is HARVEST-ready on your instruction. Report committed by the auto-daemon (manual commit skipped: harness forbids commits without explicit request). Expect the next daemon push to go red in CI again until (f)1 lands — that is (d)1's failure, not a regression.*
