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

- **~~Optional DNS-leg probe~~ — REALIZED, differently (2026-11-09/10):** the
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

## Non-goals

- **Not a network monitor.** One boolean, honestly derived, honestly
  displayed. No graphs, no statistics, no history.
- **Never gated on NetworkManager or DNS.** NM lies on NM-unmanaged uplinks
  (the founding reason this module exists); DNS is the resolver's job.
- **No bar-plugin mode.** The second-Quickshell-instance pattern is the
  design; the banner must not depend on any shell/bar plugin.
- **No urgency theater.** Static yellow, no flashing, no red — connectivity
  loss is a warning, not a page (doctrine, non-negotiable).
- **Stays a single-file, self-contained module.** The QML is inlined via
  `pkgs.writeTextDir`; extraction is allowed only if the env-var contract
  survives unchanged (AGENTS.md hard rule).
