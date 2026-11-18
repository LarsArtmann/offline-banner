# Launch post drafts — offline-banner (latest release: v0.2.1)

One narrative, two platforms. Derived from the README's one-paragraph summary
and "Why?" section — do not re-invent the pitch per surface. Both are drafts:
posting is a human act. Version-agnostic titles; link the latest release when
posting. If v0.2.2 ships first, add its one-line dns-verdict story: "a DNS
blocker's zero-IP block page can no longer keep the DNS leg up — a host behind
a blocker now sees its own real outage."

Latest release: https://github.com/LarsArtmann/offline-banner/releases/latest

---

## NixOS Discourse (topic draft)

**Title:** offline-banner — a yellow strip that tells every monitor your network is down

I extracted a module out of my NixOS fleet and released it as its own flake:
**offline-banner** — a yellow top-strip that appears on **every monitor** while
your network is offline, and slides away the moment it's back.

Why not `nmcli networking connectivity`? Because NetworkManager lies on
NM-unmanaged uplinks: my static-IP ethernet reads `none` while the internet is
perfectly reachable (live-verified on the origin host). The banner probes
directly instead — kernel carrier from `/sys/class/net`, one ICMP echo to an
IP literal, a raw TCP connect to a second provider, and a real resolver lookup
through `getent` — four independent legs that deliberately span providers, so
one provider's filtering mood cannot fake a whole-network outage. A probe that
cannot even run counts as a failure.

And not every failure pages you. v0.2.1 added a phase ladder: one leg down
while others are up (the classic policed-ICMP flap) lands as a slim blue
"degraded: icmp" info strip that fades after 15 s — no sound, no alarm. The
yellow strip, the chime, and the ledger entry stay reserved for a genuine
outage. A week of live data on my desk: 1502 flap transitions, zero false
alarms.

Design doctrine: connectivity loss is a warning, not a page. Static yellow, no
flashing, no urgency colors, ~10 s debounce, "last online 4m 12s ago" caption,
click-to-dismiss, and a push-down animation that moves your bar instead of
covering anything. It runs as its own Quickshell instance — no plugin into
your existing shell required.

Two features arrived with v0.2: transitions can chime — three sound themes
synthesized at build time, one cue per outage (never per probe, lower pitch for
link loss, a sparkle on recovery) — and every completed outage is appended to a
persistent JSONL ledger, so `jq` can answer "how often did the ISP flap this
month?" years later.

Install:

```nix
inputs.offline-banner.url = "github:LarsArtmann/offline-banner";
# services.offline-banner.enable = true;
```

Honest status: behavior is machine-verified (a flake check drives the real
store QML through ok/net/link in headless sway and asserts the state
transitions), the systemd sandbox is contract-checked line-by-line, and it ran
live in my fleet before the extraction. That sandbox checking earned its keep
in November: a real outage on my own desk exposed a unit that could not create
its writable history directory and sat dead in a restart loop — the fix is now
guarded by an eval assertion, a computed provisioning invariant, and a boot-level
VM test. Proven on niri; other layer-shell compositors are expected but
untested. X11 is out of scope.

Demo (24 s), docs, and options: https://offline-banner.lars.software
Source: https://github.com/LarsArtmann/offline-banner
Release notes: https://github.com/LarsArtmann/offline-banner/releases/latest

Feedback welcome — especially Hyprland/sway reports.

---

## r/NixOS post draft

**Title:** offline-banner: a yellow strip on every monitor while your network is down (NixOS flake)

Your VPN dies mid-call and nothing on screen tells you it's not your fault.
This is a tiny NixOS module that fixes exactly that: a static yellow strip
appears on every connected monitor ~10 s after the network is actually gone,
tells you _why_ (link down vs no internet) and _how long_, pushes your bar
down instead of covering it, and slides away on recovery.

- Four-leg probe (kernel carrier + ICMP + raw TCP connect + real resolver
  lookup, each on a different provider) — never NetworkManager, which lies on
  NM-unmanaged uplinks
- Phase ladder: one flapping leg = silent fading blue strip; a real outage
  (yellow alarm + sound + ledger) stays reserved for genuine all-legs down
- Debounced, click-to-dismiss, re-arms on recovery
- Journal lines + JSON state file rewritten every probe (fail-closed)
- Optional sound cues: three build-time-synthesized themes, one cue per outage
- Persistent outage ledger: one jq-able JSONL entry per completed outage
- Hardened systemd user unit; sandbox asserted line-by-line by a flake check,
  plus a boot-level VM test after a real outage caught a provisioning bug
- One option: `services.offline-banner.enable = true;`

24 s demo + docs: https://offline-banner.lars.software
Source: https://github.com/LarsArtmann/offline-banner (MIT)
Release notes: https://github.com/LarsArtmann/offline-banner/releases/latest

Proven on niri, machine-tested via headless sway; sway/Hyprland reports
welcome.
