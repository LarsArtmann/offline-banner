# Launch post drafts — offline-banner v0.1.0

One narrative, two platforms. Derived from the README's one-paragraph summary
and "Why?" section — do not re-invent the pitch per surface. Both are drafts:
posting is a human act.

---

## NixOS Discourse (topic draft)

**Title:** offline-banner — a yellow strip that tells every monitor your network is down

I extracted a module out of my NixOS fleet and released it as its own flake:
**offline-banner** — a yellow top-strip that appears on **every monitor** while
your network is offline, and slides away the moment it's back.

Why not `nmcli networking connectivity`? Because NetworkManager lies on
NM-unmanaged uplinks: my static-IP ethernet reads `none` while the internet is
perfectly reachable (live-verified on the origin host). The banner probes
directly instead — kernel carrier from `/sys/class/net` plus one ICMP echo to
an IP literal (no DNS dependency: the resolver is half-broken exactly when the
banner matters). A probe that cannot even run counts as a failure.

Design doctrine: connectivity loss is a warning, not a page. Static yellow, no
flashing, no urgency colors, ~10 s debounce, "last online 4m 12s ago" caption,
click-to-dismiss, and a push-down animation that moves your bar instead of
covering anything. It runs as its own Quickshell instance — no plugin into
your existing shell required.

Install:

```nix
inputs.offline-banner.url = "github:LarsArtmann/offline-banner";
# services.offline-banner.enable = true;
```

Honest status: behavior is machine-verified (a flake check drives the real
store QML through ok/net/link in headless sway and asserts the state
transitions), the systemd sandbox is contract-checked line-by-line, and it ran
live in my fleet before the extraction. Proven on niri; other layer-shell
compositors are expected but untested. X11 is out of scope.

Demo (24 s), docs, and options: https://offline-banner.lars.software
Source: https://github.com/LarsArtmann/offline-banner

Feedback welcome — especially Hyprland/sway reports.

---

## r/NixOS post draft

**Title:** offline-banner: a yellow strip on every monitor while your network is down (NixOS flake, v0.1.0)

Your VPN dies mid-call and nothing on screen tells you it's not your fault.
This is a tiny NixOS module that fixes exactly that: a static yellow strip
appears on every connected monitor ~10 s after the network is actually gone,
tells you *why* (link down vs no internet) and *how long*, pushes your bar
down instead of covering it, and slides away on recovery.

- Two-leg probe (kernel carrier + one ICMP to an IP literal) — never
  NetworkManager, which lies on NM-unmanaged uplinks
- Debounced, click-to-dismiss, re-arms on recovery
- Journal lines + JSON state file rewritten every probe (fail-closed)
- Hardened systemd user unit; sandbox asserted by a flake check
- One option: `services.offline-banner.enable = true;`

24 s demo + docs: https://offline-banner.lars.software
Source: https://github.com/LarsArtmann/offline-banner (MIT)

Proven on niri, machine-tested via headless sway; sway/Hyprland reports
welcome.
