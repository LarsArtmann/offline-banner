<!-- ROADMAP.md — long-term direction and raw ideas. No bounded tasks, no
     status indicators. When an idea is refined into bounded work, it moves to
     TODO_LIST.md. -->

# Roadmap

> Long-term direction and raw ideas. Items here are NOT actionable tasks —
> bounded work lives in TODO_LIST.md. Ideas are deliberately unrefined.

## Themes

### 1. Probe expressiveness

The probe answers one boolean honestly. Ideas that could widen what it can
say without compromising that honesty:

- **Optional DNS-leg probe — REALIZED, differently (2026-11-09/10):** the
  legs build shipped a DNS leg as a permanent third net leg (`dnsProbeName`,
  default `one.one.one.one` via `getent`), not an opt-in: the legs deliberately
  span providers so one provider's filtering mood cannot fake an outage, and
  the phase ladder keeps a DNS-only failure at "degraded" (info strip, never
  the alarm) — so the resolver still cannot page the user by default. The
  original doctrine concern is answered by the ladder, not by an option.
- **Multi-host `probeHost` semantics** — probe several targets and decide
  any-success vs all-fail. Decision first, code second: the semantics change
  what "offline" means. (The tcp leg's IP-literal + the icmp/dns legs already
  give three independent targets; revisit only if a real single-provider
  outage class appears that the ladder still mislabels.)
  - *Semantics memo (2026-11-18, implementation gated on owner).* The two
    modes are one decision: any-success across N targets ≡ all-fail on the
    inverted per-target legs. **All-fail per leg** (a leg goes down only when
    EVERY target fails) is the only mode worth wanting — it makes one
    provider's ICMP filtering unable to drop the icmp leg at all. But the
    ladder already buys that with provider-spanning legs: a Quad9-only
    filtering mood lands as *degraded* (icmp down, tcp+dns up — silent blue,
    no alarm), which the gen-995 week machine-proved 1502 times. **What
    multi-host cannot change**: the *offline* phase needs tcp+dns down (or
    all three net legs), and a genuine multi-provider co-outage fails every
    leg with or without extra targets — the alarm fires correctly in both
    worlds. **What it would cost**: probe time scales with targets under the
    probe-overlap assertion; denser probing invites exactly the policing that
    motivated the ladder; the state schema (`legs.*` objects) and every
    consumer (contrib script, DMS plugin, ledger reasons) become per-target
    structures — a breaking state-format change. **Verdict**: do not build
    on speculation; the trigger stays a REAL documented mislabel (a captured
    outage the ladder graded wrong). If that ever lands, the minimal honest
    step is ONE second `probeHost2` ping target as its own leg (default
    mirroring `probeHost` keeps it off), never target arrays inside legs.

### 2. Operational smoothness

Today, tuning means a drop-in override plus a unit restart (env is read at
process start). Raw directions:

- **Live retuning without restart** — an IPC channel or watched file so
  interval/threshold changes apply to a running banner.
- **`ExecReload` story** — or an explicit, documented restart-only contract
  for tuning.

### 3. Verification depth

The module is contract-checked; behavior is machine-proven (probe-transitions
leg/ladder scenarios, render-smoke yellow+blue pixel gates) and live-proven on
evo-x2 (gen 995, first real ledger append 2026-11-10). The boot-level VM test
is BUILT (`packages.vm-smoke`, negative-proven) and awaits the D1 decision on
blocking-vs-advisory. Beyond that:

- **Second-compositor proof** — README targets any layer-shell compositor;
  only niri is proven. A Hyprland pass would turn that claim from expected
  into tested.

### 4. Sound & ledger expressiveness (raw ideas, 2026-10-29)

The cue/ledger machinery shipped; where it could widen without breaking the
warning-not-page doctrine:

- **More themes / per-event overrides** — birds, synthwave, an ultra-quiet
  "subtle" set; or per-event config (silent dismiss + loud recover).
- **Quiet-hours awareness** — respect a DND/presence signal.
- **"Still offline" reminder** — a cue every N minutes during LONG outages
  (doctrine tension: warning vs page — decide before building).
- **Custom theme from a user dir** — point an option at your own wavs.
- **Ledger analytics** — contrib stats script (totals/worst per week),
  waybar tail widget, retention policy question (owner taste).
- **Crash-proof paired-event ledger** — open/close event lines instead of
  completed-outage lines (current format documented + accepted).
- **Ledger growth/rotation doc** — document bytes/day growth characteristics
  and rotation guidance alongside the retention question above.

### 5. Ecosystem & public-surface upkeep (raw ideas, harvested 2026-11-17)

Demand-gated or audience-gated; none of these have a pull signal yet:

- **`nixosModules.example`** — laptop-defaults example module lowering the
  try-it barrier.
- **Upstream to nixpkgs** — search.nixos.org visibility vs review burden.
- **Metrics endpoint** — tiny loopback HTTP endpoint exposing the state JSON;
  only if a consumer demands it.
- **Community-surface triggers** — CONTRIBUTING.md + issue templates when
  external contributors appear; SECURITY.md when the audience grows;
  CODEOWNERS stays skip while single-maintainer.
- **Demand-gated video variants** — 9:16 vertical cut, TTS voiceover +
  captions, a ≤6 s 480p GIF teaser for Discord/Telegram, a YouTube cut with
  chapters — build only when a channel exists.
- **Omarchy / non-NixOS install path** — extracted QML + a plain systemd
  user unit + install snippet for Arch-class hosts (Omarchy is systemd +
  Hyprland + quickshell-from-pacman; the second-instance pattern beside
  `omarchy-shell` is the same shape proven daily beside DankMaterialShell).
  Demand-gated: the shell-compatibility docs page points Omarchy users at
  the issue tracker — that is the promoting signal. The _plugin_ route is
  closed by doctrine on both sides (Omarchy: plugins share the
  omarchy-shell process, "never start a second Quickshell process for a
  plugin"; this repo: no bar-plugin mode, non-negotiable below).

## Non-goals

- **Not a network monitor.** One boolean, honestly derived, honestly
  displayed. No graphs, no statistics, no history.
- **Never gated on NetworkManager or DNS.** NM lies on NM-unmanaged uplinks
  (the founding reason this module exists); DNS is the resolver's job.
- **No bar-plugin mode.** The second-Quickshell-instance pattern is the
  design; the banner must not depend on any shell/bar plugin. Re-evaluated
  2026-11-18 for Omarchy's plugin marketplace and declined: Omarchy plugins
  share the `omarchy-shell` process — no sandbox, no env contract, no crash
  isolation — the standalone unit is the shape on Omarchy too (docs:
  shell-compatibility guide).
- **No urgency theater.** Static yellow, no flashing, no red — connectivity
  loss is a warning, not a page (doctrine, non-negotiable).
- **Stays a single-file, self-contained module.** The QML is inlined via
  `pkgs.writeTextDir`; extraction is allowed only if the env-var contract
  survives unchanged (AGENTS.md hard rule).
