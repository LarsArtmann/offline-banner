# offline-banner

A yellow top-strip banner for NixOS desktops that appears on **every monitor** while your network is offline — and slides away the moment it's back.

Connectivity loss is a **warning, not a page**: the banner is a static, non-flashing yellow strip (no blinking, no urgency colors) that shows up ~10 seconds after the network is actually gone, tells you *why* ("Network link is down" vs "No internet connection") and *when* you were last online, and dismisses on click if you've seen it.

## Why not `nmcli networking connectivity`?

Because NetworkManager lies on servers and hybrid hosts: a static-IP ethernet uplink is NM-unmanaged, so NM's connectivity state reads `none` while the internet is perfectly reachable (live-verified on the origin host). The probe is a two-leg shell check instead:

1. **Link leg** — any real interface (lo/veth/tailscale/wireguard/docker/... excluded) with `carrier 1`, read straight from `/sys/class/net`. No carrier → *"Network link is down"*.
2. **Internet leg** — one ICMP echo to `probeHost` (default `9.9.9.9`, an **IP, not a name**: DNS is often half-broken exactly when the banner matters, and the banner must never depend on the resolver). No echo → *"No internet connection"*.

A probe that cannot even run counts as a failure — fail visible, never fail silent.

## Behavior

- **Debounced**: `failuresToShow` consecutive failed probes (default 2 × 5 s ≈ 10 s) before appearing; hides on the *first* clean probe. No flash on a single lost ping.
- **Push-down, not cover**: the strip is a `WlrLayer.Top` layer-shell surface with `ExclusionMode.Auto` and an **animated height** (InOutCubic, 450 ms) — a top-anchored bar gets pushed down beneath it frame by frame and slides back up on recovery. Nothing is covered; nothing underneath is unreachable.
- **Last-online caption**: "last online 4m 12s ago" (or `unknown` early in the session), re-evaluated every second while visible.
- **Click to dismiss**: hides for the rest of *this* outage; the next clean probe re-arms it so a fresh outage shows again.
- **Own Quickshell instance**: renders as a second [Quickshell](https://quickshell.outfoxxed.me/) process — no plugin into your existing shell/bar required, works with any layer-shell compositor (niri, Hyprland, ...).

## Quickstart

```nix
# flake.nix
inputs.offline-banner.url = "github:LarsArtmann/offline-banner";
```

```nix
# your NixOS configuration
{
  imports = [ inputs.offline-banner.nixosModules.default ];
  services.offline-banner.enable = true;
}
```

The unit is a `systemd.user` service bound to `graphical-session.target` — it starts with the graphical session, one banner surface per connected monitor.

## Options

| Option                 | Type    | Default         | Description                                                                   |
| ---------------------- | ------- | --------------- | ----------------------------------------------------------------------------- |
| `enable`               | bool    | `false`         | Enable the banner                                                             |
| `package`              | package | `pkgs.quickshell` | Quickshell package to run                                                     |
| `checkIntervalSeconds` | int > 0 | `5`             | Seconds between connectivity probes                                           |
| `probeHost`            | string  | `"9.9.9.9"`     | IP pinged for the internet leg (keep it an IP, not a name)                    |
| `probeTimeoutSeconds`  | int > 0 | `3`             | ping timeout (asserted `< checkIntervalSeconds` — probes must never overlap)  |
| `failuresToShow`       | int > 0 | `2`             | Consecutive failed probes before the banner appears (debounce)                |
| `layerNamespace`       | string  | `"offline-banner"` | WlrLayershell namespace (find the surface via e.g. `niri msg layers`)       |

## Runtime tuning & demos

The unit's `OFFLINE_BANNER_{INTERVAL,PROBE_HOST,PROBE_TIMEOUT,FAILURES}` environment variables mirror the options — a drop-in override (`systemctl --user edit offline-banner`) retunes a live system without a rebuild, and forcing `PROBE_HOST` to an unroutable IP forces the banner visible for demos.

## Provenance

Extracted from [SystemNix](https://github.com/LarsArtmann/SystemNix) (`modules/nixos/desktop/offline-banner.nix`, deployed as gen 904) on 2026-10-16, at v3 behavior: bar push-down animation, last-online caption, click-dismiss.
