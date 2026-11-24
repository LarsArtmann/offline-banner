<!-- docs/DOMAIN_LANGUAGE.md — the ubiquitous language of offline-banner.
     Domain terms, not implementation details. Built 2026-11-23 from
     module.nix vocabulary; every term is greppable in the codebase. -->

# Domain Language

> The ubiquitous language of offline-banner: one NixOS module that watches the
> network and, when the internet is actually gone, pushes a yellow strip under
> the bar — honestly derived, honestly displayed. Terms below are the ones the
> code, the journal, the state file, and every doc use. A doc that means
> something else by one of these words is a doc that lies.

## Core terms

| Term                | Definition                                                                                                                                                                    | Where used                                   |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------- |
| Leg                 | One independently-debounced connectivity check: **link** (carrier), **icmp** (echo to `probeHost`), **tcp** (connect to `tcpProbeHost:tcpProbePort`), **dns** (lookup of `dnsProbeName`). | `module.nix` probe/netProbe; `leg down/ok leg=…` |
| Debounce            | The consecutive-failure count a leg must reach before it counts as down (`failuresToShow`, default 2). Sub-debounce blips never change phase, never cue, never ledger.          | `failuresToShow` option; journal `failures=N/M` |
| Phase               | The coarse state derived from the down legs: **online** (no leg down), **degraded** (a leg down but the ladder says usable), **offline** (an outage for practical purposes).     | state file `phase`; journal `banner phase=…`  |
| The ladder          | The offline rule set: link down, OR tcp+dns both down, OR icmp+tcp both down. Two dead transport legs decide — a resolver's record cache must never outrank them.                | `module.nix` `offline` binding                |
| Outage              | A completed episode whose start is the first debounced failure and whose end is full recovery (every leg back up). One outage = one ledger entry + one show cue + one recover cue. | ledger entries; `outage ended from=…` journal |
| Flap                | Rapid oscillation of a leg across its debounce while another leg stays down. A flap hops the phase offline→degraded→offline WITHOUT ending the episode (the `outageOpen` latch exists so flaps cannot multiply ledger entries or cues). | `outageOpen` latch; the flap scenario         |
| `outageOpen` latch  | The episode tracker: opens when the phase enters offline with a stamped start, closes ONLY when the phase reaches online. The ledger close and the cues ride it — never the raw offline flips. | `module.nix` `onPhaseChanged`                 |
| Degraded dwell      | How long the degraded strip stays visible before auto-fading (`degradedDwellSeconds`; 0 = sticky). A NEW down-leg set re-arms it; an unchanged set never re-shows (flash doctrine). | `degradedDwellSeconds` option; `dwellExpired`  |
| Re-arm              | What lets a silenced banner return: the offline banner re-arms on full recovery; the degraded strip re-arms on a NEW down-leg set (compared on the raw set, never the signal).   | `dismissed`, `lastDownLegsKey`                |
| Dismissal           | A user click that hides the banner for the REST of the outage; journal token `banner state=dismissed rearm=next_clean_probe`.                                                  | MouseArea; `scripts/click-dismiss-proof.sh`   |
| State file          | `$XDG_RUNTIME_DIR/<state-dir>/state`, rewritten every probe — the freshness heartbeat (older than ~2 intervals = dead unit, fail closed). Consumers only ever see a complete file (tmp+mv). | `emitState()`; `contrib/offline-banner-waybar` |
| Ledger (outage history) | `historyPath` JSONL: one entry per completed outage — `from`/`to`/`durationSec`/`reasons`/`probeFailures`. Open outages and demo never write.                              | `rememberOutage()`; `history.jsonl`           |
| Cue                 | One synthesized sound at an episode boundary: show (lower pitch for link), recover, dismiss tick. One per boundary, never per probe or per phase hop.                          | `playSound()`; `sounds.log` in tests          |
| Demo                | `OFFLINE_BANNER_DEMO=1` force-shows with probes skipped; a FAKE outage: no ledger write, no cue (the state file carries `demo:true` so nobody mistakes it for a real outage).   | `demo` property; smoke app                    |
| Probe seams         | The env-injected test surfaces (`OFFLINE_BANNER_PROBE_CMD`, `OFFLINE_BANNER_NET_PROBE_CMD`, `OFFLINE_BANNER_SOUND_CMD`, `OFFLINE_BANNER_HISTORY`, `OFFLINE_BANNER_STATE_DIR`) that let the real QML run headless against scripted probes. | `probe-transitions`; `render-smoke`           |
| Unit-managed env    | The `OFFLINE_BANNER_*` variables the module derives from its options — a public surface for live tuning; when unset (bare run, tests, demos) sound and history stay inert.       | `module-contract` gate; README tuning section |

## Bounded contexts

| Term   | Context A (meaning)                                                          | Context B (meaning)                                       |
| ------ | ---------------------------------------------------------------------------- | --------------------------------------------------------- |
| reason | The probe-level cause string (`link`/`net`) in journal and state file        | A human cause in ledger `reasons` (`net,tcp,dns,link`)     |
| down   | A leg past its debounce (`legDown` bindings drive the ladder)                | The raw counter being nonzero (`tcpFailures` mid-debounce) |

The first is the debounced, decision-grade fact; the second is the raw counter
the change handlers MUST decide on (bindings render, functions decide — the
CI-proven stale mid-cascade class).

## Deprecated terms

| Old term            | Current term   | Why changed                                                                       |
| ------------------- | -------------- | --------------------------------------------------------------------------------- |
| `nmcli` check       | Four-leg probe | The original single-command check could not tell a dead NIC from a dead WAN       |
| `OFFLINE_BANNER_DEGRADED_DWELL` ms-vs-s ambiguity | seconds in the option, milliseconds in the env | Fixed 2026-11-23 at the emission boundary; the env contract stays milliseconds |
