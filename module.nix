# Yellow top-strip banner (Quickshell layer-shell) while the desktop is offline.
#
# What "offline" means here and why the probe is NOT `nmcli networking
# connectivity`: NetworkManager often manages WiFi only — a static-IP
# ethernet uplink is NM-unmanaged and NM's connectivity state reads "none"
# even while the internet is perfectly reachable (live-verified on the
# origin host 2026-10-16). The probe is a multi-leg check instead:
#   1. any real interface (lo/veth/tailscale/wg/... excluded) with carrier 1
#      — else "link" (cable out / wifi dead);
#   2. an ICMP echo to the probe host (default 9.9.9.9) — else "net"
#      (router up, WAN down). An IP, not a name: DNS can be half-broken
#      exactly when the banner matters, and coupling the banner to the
#      resolver would blackhole it then.
#
# INDEPENDENT LEGS (2026-11-09): reachability is not ONE boolean — the
# legs are tracked separately, each with its own consecutive-failure
# debounce (failuresToShow), because they fail for different reasons:
#   3. tcp — a TCP connect to tcpProbeHost:tcpProbePort (default
#      1.1.1.1:53, an IP literal: no resolver involved);
#   4. dns — resolving dnsProbeName (default one.one.one.one) via
#      `getent ahostsv4` — the glibc/NSS path applications actually
#      use, so a local-resolver (dnsblockd-style) outage registers
#      here and nowhere else.
# The legs deliberately span providers (Quad9 / Cloudflare / whatever
# the system resolver is): independent legs must not share one
# provider's filtering mood. ICMP is the most policed leg — flow
# policing drops single echo requests while browsing works fine (the
# 2026-11-09 evo-x2 flap: single pings lost ~30-50% to the full 3 s
# timeout while a dense single-flow ping stream passed 100% and
# TCP/DNS were instant — the banner kept crying "offline" every few
# seconds over a perfectly usable network).
#
# SMART DISPLAY — the phase ladder (2026-11-09):
#   offline  = link down, or tcp+dns BOTH down (internet unusable for
#              practical purposes), or all three net legs down — the
#              yellow alarm: sound cue, outage ledger, "last online";
#   degraded = a leg down while at least one other leg is up (the
#              policed-ICMP case: browsing is fine) — a slim info-blue
#              strip naming the down legs, NO sound, NO ledger entry,
#              auto-fading after degradedDwellSeconds; it re-appears
#              only when the SET of down legs changes (one flapping
#              leg must not flash the strip — the every-few-seconds
#              banner cycle is exactly what this kills);
#   online   = all legs up.
# Everything observable stays ADDITIVE: journal/state surfaces the
# original single-probe contract used keep their exact tokens (the
# SystemNix verification recipes and the probe-transition greps).
# `ping` needs no wrapper on NixOS (nixpkgs iputils ships cap_net_raw).
#
# INDEPENDENT LEGS (2026-11-09): reachability is not ONE boolean — the
# legs are tracked separately, each with its own consecutive-failure
# debounce (failuresToShow), because they fail for different reasons:
#   1. link — any real interface (lo/veth/tailscale/wg/... excluded)
#      with carrier 1 (cable out / wifi dead);
#   2. icmp — an ICMP echo to probeHost (default 9.9.9.9). An IP, not a
#      name: DNS must not gate the banner. ICMP is the MOST POLICED leg
#      — burst/flow policing drops single echo requests while browsing
#      works fine (the 2026-11-09 evo-x2 flap: single pings lost ~30-50%
#      to a full 3 s timeout while a dense single-flow ping stream
#      passed 100% and TCP/DNS were instant);
#   3. tcp — a TCP connect to tcpProbeHost:tcpProbePort (default
#      1.1.1.1:53, an IP literal: no resolver involved);
#   4. dns — resolving dnsProbeName (default one.one.one.one) via
#      `getent ahostsv4` — the glibc/NSS path applications actually
#      use, so a local-resolver outage shows here and nowhere else.
# The legs deliberately span providers (Quad9 / Cloudflare / whatever
# the system resolver is): independent legs must not share one
# provider's filtering mood.
#
# SMART DISPLAY — the phase ladder (2026-11-09):
#   offline  = link down, or tcp+dns BOTH down (internet unusable for
#              practical purposes), or all three net legs down — the
#              yellow alarm: sound cue, outage ledger, "last online";
#   degraded = a leg down while at least one other leg is up (the
#              policed-ICMP case: browsing is fine) — a slim info-blue
#              strip naming the down legs, NO sound, NO ledger entry,
#              auto-fading after degradedDwellSeconds; it re-appears
#              only when the SET of down legs changes (a flapping leg
#              must not flash the strip — the old every-7-seconds
#              banner cycle is exactly what this kills);
#   online   = all legs up.
# Everything observable stays additive: the journal/state surfaces the
# original single-probe contract used keep their tokens.
#
# Rendering follows the second-Quickshell-instance pattern, with ONE
# owner-requested difference (2026-10-16): the strip lives on the TOP layer
# with ExclusionMode.Auto and an ANIMATED height, so instead of floating
# over the bar it CLAIMS the top edge and the bar slides down beneath it
# (slow InOutCubic push, slides back up on recovery).
# Rendered as a second Quickshell instance by deliberate choice (2026-10-16):
# zero dependence on any shell/bar plugin API. The stronger claim once
# considered — that DMS plugins cannot render layer-shell surfaces — was
# reasoned, never tested; the pattern stands on independence, not on it. DISMISSABLE: clicking anywhere on the strip
# slides it up for the rest of the outage; the next clean probe re-arms
# it, so a fresh outage shows again. The strip therefore takes pointer
# input (no click-through mask) — the bar has been pushed below it, so
# nothing clickable is underneath.
# STATIC yellow — the "non-flashing yellow" doctrine (2026-09-02):
# connectivity loss is a warning, not a page. The banner appears after
# `failuresToShow` consecutive failed probes (default 2 = ~10 s grace, no
# flash on a single lost ping) and hides on the first clean probe; a 1 s
# display tick keeps the "last online X ago" caption honest while it is
# up. A probe that cannot even run (empty output) counts as "net" — fail
# visible, never fail silent.
#
# SOUNDS (2026-10-28): the banner's audible twin rides the SAME
# warning-not-page doctrine — one short, soft cue per OUTAGE (never per
# probe, never looping): a gentle droop when the banner appears (lower
# pitch for link loss — the "heavier" failure), an ascending sparkle on
# recovery, a near-inaudible tick on dismiss. Three themes, synthesized
# at build time by inline Python (stdlib only — no audio assets, no
# fetch): chime (sine), droplet (pitch-bent plips), retro (8-bit
# square); "none" opts out. Playback is pw-play against the session
# PipeWire over its AF_UNIX socket (already in RestrictAddressFamilies
# — the same hole Wayland uses); a bare `quickshell -p` run (env unset)
# is silent, so tests and demos never beep.
#
# OUTAGE LEDGER (2026-10-28): every COMPLETED outage appends one JSON
# line — from (first failed probe of the run), to (the clean probe that
# ended it), durationSec, reasons, probeFailures — to a persistent
# XDG-state file, so "how long were we offline this month?" is one jq.
# Sub-debounce blips never become entries (they are not outages by this
# module's definition); an outage still open when the unit stops is
# lost (documented, accepted — the journal still holds the transitions);
# demo mode never writes (it is a fake outage). The ledger dir is the
# unit's ONLY writable home path (ReadWritePaths hole under
# ProtectHome=read-only).
#
# Extracted from SystemNix (modules/nixos/desktop/offline-banner.nix,
# deployed there as gen 904 v1 — verified: SystemNix live-session report
# anchors /run/current-system == 904; v2/v3 were demo-proven, not deployed)
# 2026-10-16.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.services.offline-banner = {
    enable = lib.mkEnableOption "yellow top-strip banner on every monitor while the network is offline (Quickshell layer-shell)";

    package = lib.mkPackageOption pkgs "quickshell" { };

    checkIntervalSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 5;
      description = "Seconds between connectivity probes";
    };

    probeHost = lib.mkOption {
      type = lib.types.str;
      default = "9.9.9.9";
      description = "IP pinged for the internet-reachability leg (an IP, not a name — DNS is the resolver's job and must not gate the banner). The default is an IPv4 literal: on a v6-primary uplink with a broken v4 route the banner shows offline while v6 browsing works — accepted tradeoff; point this at a v6 literal on v6-primary hosts (iputils ping dials it directly)";
    };

    probeTimeoutSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3;
      description = "ping timeout in seconds (must stay below checkIntervalSeconds)";
    };

    failuresToShow = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2;
      description = "Consecutive failed probes before a leg counts as down and the banner appears (debounce) — each leg (icmp/tcp/dns) debounces independently against this value";
    };

    tcpProbeHost = lib.mkOption {
      type = lib.types.str;
      default = "1.1.1.1";
      description = "IP for the TCP-connect leg — an IP literal, deliberately: the tcp leg measures raw socket reachability without touching the resolver (name lookups are the separate dnsProbeName leg). Deliberately a different anycast provider than probeHost (Quad9): independent legs must not share a single provider's filtering mood";
    };

    tcpProbePort = lib.mkOption {
      type = lib.types.port;
      default = 53;
      description = "Port for the TCP-connect leg. 53 (DNS-over-TCP) survives almost every consumer firewall that passes DNS at all, while fancy ports (443-class captive portals, proxies) can lie the other way";
    };

    dnsProbeName = lib.mkOption {
      type = lib.types.str;
      default = "one.one.one.one";
      description = "Name resolved by the DNS leg via `getent ahostsv4` — the glibc/NSS path applications actually use, so a local-resolver (dnsblockd-style) outage registers here and nowhere else. Must be an EXTERNAL name: a wildcard-capturing local zone would answer any string and blind the leg";
    };

    degradedDwellSeconds = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 15;
      description = "Seconds the degraded (info) strip stays visible before auto-fading; 0 = sticky while degraded. It re-appears only when the SET of down legs changes, so one flapping leg cannot flash the strip";
    };

    layerNamespace = lib.mkOption {
      type = lib.types.str;
      default = "offline-banner";
      description = "WlrLayershell namespace of the banner surfaces (visible via compositor layer tools, e.g. `niri msg layers`)";
    };

    soundTheme = lib.mkOption {
      type = lib.types.enum [
        "chime"
        "droplet"
        "retro"
        "none"
      ];
      default = "chime";
      description = "Sound theme for banner transitions — synthesized at build time (no audio assets): `chime` (soft sine: two-note droop on offline, ascending sparkle on recovery), `droplet` (pitch-bent water plips), `retro` (8-bit square-wave power-down/level-up), `none` (silence). One cue per outage (never per probe): lower pitch for link loss than for net loss, a sparkle on recovery, a quiet tick on dismiss. Playback runs `pw-play` against the session PipeWire (its AF_UNIX socket is already allowed by the sandbox)";
    };

    soundVolume = lib.mkOption {
      type = lib.types.ints.between 0 100;
      default = 60;
      description = "Playback volume in percent, passed to pw-play as a linear factor (0 mutes without disabling the theme); PipeWire may apply its own stream volume on top";
    };

    enableHistory = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Append one JSON line per completed outage to historyPath: `{from, to, durationSec, reasons, probeFailures}` (epoch seconds). Outages shorter than the debounce never become entries; an outage still open when the unit stops is not written; demo mode never writes";
    };

    historyPath = lib.mkOption {
      type = lib.types.str;
      default = "%h/.local/state/offline-banner/history.jsonl";
      description = "Absolute path of the persistent outage log (JSON Lines). %h/%t systemd unit specifiers expand (in unit-file Environment= and ReadWritePaths); the parent directory becomes the unit's only writable path under the read-only home AND must be one the unit provisions itself — %h/.local/state/<name> (created via StateDirectory=) or %t/offline-banner (created via RuntimeDirectory=). Other shapes fail eval: ReadWritePaths binds but never creates, and an unprovisioned parent kills the unit at startup (status 226/NAMESPACE restart loop — the 2026-11-05 evo-x2 outage)";
    };
  };

  config =
    let
      cfg = config.services.offline-banner;

      offlineBannerShell = pkgs.writeTextDir "shell.qml" ''
        pragma ComponentBehavior: Bound

        import QtQuick
        import Quickshell
        import Quickshell.Io
        import Quickshell.Wayland

        ShellRoot {
            id: root

            readonly property int intervalMs: {
                const raw = Quickshell.env("OFFLINE_BANNER_INTERVAL");
                const parsed = raw ? parseInt(raw) : 5000;
                return parsed > 500 ? parsed : 5000;
            }
            readonly property int failuresToShow: {
                const raw = Quickshell.env("OFFLINE_BANNER_FAILURES");
                const parsed = raw ? parseInt(raw) : 2;
                return parsed > 0 ? parsed : 2;
            }
            // Leg targets (2026-11-09): TCP and DNS legs join the ICMP leg.
            // Env unset (bare quickshell -p, tests) = the same defaults the
            // module passes — a bare run still probes all three legs.
            readonly property string tcpHost: Quickshell.env("OFFLINE_BANNER_TCP_HOST") || "1.1.1.1"
            readonly property string tcpPort: Quickshell.env("OFFLINE_BANNER_TCP_PORT") || "53"
            readonly property string dnsName: Quickshell.env("OFFLINE_BANNER_DNS_NAME") || "one.one.one.one"
            readonly property int degradedDwellMs: {
                const raw = Quickshell.env("OFFLINE_BANNER_DEGRADED_DWELL");
                const parsed = raw ? parseInt(raw) : 15000;
                return parsed >= 0 ? parsed : 15000;
            }
            // OFFLINE_BANNER_NET_PROBE_CMD (internal, test-only — NOT part
            // of the public env contract): replaces the whole TCP+DNS
            // probe script (same doctrine as OFFLINE_BANNER_PROBE_CMD for
            // the carrier+icmp probe). It must print exactly two lines:
            // "tcp ok|fail" then "dns ok|fail".
            readonly property var netProbeOverride: {
                const raw = Quickshell.env("OFFLINE_BANNER_NET_PROBE_CMD");
                return raw ? ["sh", "-c", raw] : [];
            }

            // Demo mode (OFFLINE_BANNER_DEMO=1): force the banner visible
            // with no probes at all — safe demos and post-deploy checks,
            // no unroutable-IP drop-in hack required.
            readonly property bool demo: Quickshell.env("OFFLINE_BANNER_DEMO") === "1"

            // OFFLINE_BANNER_PROBE_CMD (internal, test-only — NOT part of
            // the public env contract): replaces the whole probe script.
            // The probe-transition check drives ok/net/link with a stub
            // this way, in-sandbox and network-free.
            readonly property var probeOverride: {
                const raw = Quickshell.env("OFFLINE_BANNER_PROBE_CMD");
                return raw ? ["sh", "-c", raw] : [];
            }

            // Sounds (see the module header for the doctrine): env unset
            // (bare `quickshell -p` runs, tests, demos) = "none" = silence
            // — the unit always passes the theme explicitly.
            readonly property string soundTheme: {
                const raw = Quickshell.env("OFFLINE_BANNER_SOUND_THEME");
                return raw === "chime" || raw === "droplet" || raw === "retro" ? raw : "none";
            }
            // pw-play takes a linear 0..1 factor; out-of-range env falls
            // back to the module default (60), same doctrine as intervalMs.
            readonly property string soundVolumeArg: {
                const raw = Quickshell.env("OFFLINE_BANNER_SOUND_VOLUME");
                const parsed = raw ? parseFloat(raw) : 60;
                const pct = parsed >= 0 && parsed <= 100 ? parsed : 60;
                return (pct / 100).toFixed(2);
            }
            // OFFLINE_BANNER_SOUND_CMD (internal, test-only): replaces the
            // player argv — the check harness asserts WHICH event fired.
            readonly property var soundOverride: {
                const raw = Quickshell.env("OFFLINE_BANNER_SOUND_CMD");
                return raw ? ["sh", "-c", raw] : [];
            }

            // Persistent outage ledger (see the module header): env unset
            // = no file writes — bare runs and tests never touch home.
            readonly property string historyPath: Quickshell.env("OFFLINE_BANNER_HISTORY") || ""
            // First failed probe of the CURRENT failing run (epoch sec;
            // 0 = probes clean / sub-debounce blip already recovered).
            property real firstFailedAt: 0
            // Unique failure reasons of the current run, in first-seen
            // order — the ledger entry's "reasons" array.
            property var outageReasons: []

            property int failures: 0
            property string reason: ""
            // Independent leg tracking (2026-11-09): each leg keeps its OWN
            // consecutive-failure counter and debounces against
            // failuresToShow separately. failures (above) is the icmp
            // leg's counter AND the legacy one — its journal/state tokens
            // are the original single-probe contract, kept verbatim.
            property int tcpFailures: 0
            property int dnsFailures: 0
            // Total failed PROBE EVENTS across ALL legs during the
            // CURRENT failing run (icmp ticks + tcp ticks + dns ticks).
            // The ledger's probeFailures reads this at close time — a
            // leg-only outage legitimately reports 0 icmp failures but
            // still counts its own leg events.
            property int outageProbeFailures: 0
            readonly property bool icmpLegDown: root.failures >= root.failuresToShow
            readonly property bool tcpLegDown: root.tcpFailures >= root.failuresToShow
            readonly property bool dnsLegDown: root.dnsFailures >= root.failuresToShow
            readonly property bool linkDown: root.icmpLegDown && root.reason === "link"
            // Phase ladder (see the header). offline deliberately fires on
            // tcp+dns alone even with icmp green: no sockets and no names
            // IS offline for practical purposes, however chatty the icmp
            // leg still is.
            readonly property bool offline: root.demo || root.linkDown
                || (root.tcpLegDown && root.dnsLegDown)
                || (root.icmpLegDown && root.tcpLegDown && root.dnsLegDown)
            readonly property string phase: root.offline
                ? "offline"
                : ((root.icmpLegDown || root.tcpLegDown || root.dnsLegDown) ? "degraded" : "online")
            property string previousPhase: "online"
            readonly property var downLegs: {
                const legs = [];
                if (root.icmpLegDown) legs.push("icmp");
                if (root.tcpLegDown) legs.push("tcp");
                if (root.dnsLegDown) legs.push("dns");
                return legs;
            }
            readonly property string degradedLegs: root.downLegs.join(",")
            readonly property string degradedText: {
                const names = root.downLegs.map(function (l) {
                    return l === "icmp" ? "ICMP" : (l === "tcp" ? "TCP" : "DNS");
                });
                return names.join(" + ") + " down";
            }
            // Degraded strip visibility: shown on a NEW down-leg set, then
            // auto-fades after the dwell. dismissedDegraded is the strip's
            // own dismissal (separate from the offline banner's); BOTH
            // re-arm when the down-leg set changes — a fresh fact may not
            // be silenced by the previous one's dismissal.
            property bool dismissedDegraded: false
            property bool dwellExpired: false
            readonly property bool degradedVisible: root.phase === "degraded"
                && !root.dismissedDegraded
                && !root.dwellExpired
            readonly property string reasonText: root.reason === "link"
                ? "Network link is down"
                : "No internet connection"
            // Last confirmed-good probe (epoch seconds; 0 = not seen this
            // session — banner then says "unknown" instead of lying).
            property real lastOnlineAt: 0
            property int tick: 0
            // Click-to-dismiss: dismissing hides the banner for the REST
            // OF THIS OUTAGE; the next clean probe re-arms it, so a fresh
            // outage shows again.
            property bool dismissed: false
            readonly property string lastOnlineAgo: {
                root.tick;
                return root.lastOnlineAt > 0 ? root.fmtAgo(root.lastOnlineAt) : "unknown";
            }

            function fmtAgo(epochSec) {
                const s = Math.max(0, Math.floor(Date.now() / 1000 - epochSec));
                if (s < 60) return s + "s";
                const m = Math.floor(s / 60);
                if (m < 60) return m + "m " + (s % 60) + "s";
                const h = Math.floor(m / 60);
                return h + "h " + (m % 60) + "m";
            }

            function applyProbe(text) {
                const result = (text ?? "").trim().split("\n")[0];
                if (result === "ok") {
                    if (root.failures > 0)
                        console.log("[offline-banner] probe ok recovered_after=" + root.failures);
                    // The outage close itself happens in onPhaseChanged
                    // (which fires off the reset below), so the ledger's
                    // probeFailures is outageProbeFailures — the live
                    // all-leg counter, not this leg's snapshot.
                    root.lastOnlineAt = Date.now() / 1000;
                    root.failures = 0;
                    root.reason = "";
                    // Dismissal re-arms on FULL recovery (no leg down), not
                    // on any single clean probe: a dismissed banner must
                    // not pop back just because the icmp leg blipped ok
                    // while tcp/dns are still down (mid-outage). The RUN
                    // clear (ledger bookkeeping) checks the RAW counters —
                    // debounced legDown flags read false while a leg is
                    // failing below its debounce, which would wipe a run
                    // in progress (the tcp-1-of-2 + dns-ok wipe).
                    if (!root.tcpLegDown && !root.dnsLegDown) {
                        root.dismissed = false;
                        if (root.failures === 0 && root.tcpFailures === 0 && root.dnsFailures === 0) {
                            root.firstFailedAt = 0;
                            root.outageReasons = [];
                            root.outageProbeFailures = 0;
                        }
                    }
                    root.emitState();
                    return;
                }
                // "link" = carrier gone; "net" = link up, probe host
                // unreachable; anything else = the probe itself failed
                // to run — all three keep the banner honest.
                root.reason = result === "link" ? "link" : "net";
                if (root.failures === 0)
                    root.firstFailedAt = Date.now() / 1000;
                if (root.outageReasons.indexOf(root.reason) < 0)
                    root.outageReasons.push(root.reason);
                root.failures = root.failures + 1;
                root.outageProbeFailures = root.outageProbeFailures + 1;
                console.log("[offline-banner] probe failed reason=" + root.reason + " failures=" + root.failures + "/" + root.failuresToShow);
                root.emitState();
            }

            // TCP+DNS probe result (two lines: "tcp ok|fail", "dns ok|fail").
            // Per-leg mirrors of applyProbe, with leg-prefixed journal
            // tokens ("leg down/ok") so the legacy single-probe greps stay
            // exact — see the header's additivity note.
            function applyNetProbe(text) {
                const lines = (text ?? "").trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const part = lines[i].trim().split(/\s+/);
                    if (part.length !== 2)
                        continue;
                    if (part[0] === "tcp")
                        root.applyLeg("tcp", part[1] === "ok");
                    else if (part[0] === "dns")
                        root.applyLeg("dns", part[1] === "ok");
                }
            }

            function applyLeg(name, up) {
                const counter = name === "tcp" ? root.tcpFailures : root.dnsFailures;
                if (up) {
                    if (counter > 0)
                        console.log("[offline-banner] leg ok leg=" + name + " recovered_after=" + counter);
                    if (name === "tcp")
                        root.tcpFailures = 0;
                    else
                        root.dnsFailures = 0;
                    // Full recovery (no leg down after this one): same
                    // re-arm/clear contract as the probe-ok branch.
                    if (root.failures === 0 && root.tcpFailures === 0 && root.dnsFailures === 0) {
                        root.dismissed = false;
                        root.firstFailedAt = 0;
                        root.outageReasons = [];
                        root.outageProbeFailures = 0;
                    }
                    root.emitState();
                    return;
                }
                if (counter === 0) {
                    // First failure of a failing RUN (any leg may arm it —
                    // the ledger "from" is the first leg to go down).
                    if (root.firstFailedAt === 0)
                        root.firstFailedAt = Date.now() / 1000;
                    if (root.outageReasons.indexOf(name) < 0)
                        root.outageReasons.push(name);
                }
                if (name === "tcp")
                    root.tcpFailures = root.tcpFailures + 1;
                else
                    root.dnsFailures = root.dnsFailures + 1;
                root.outageProbeFailures = root.outageProbeFailures + 1;
                const after = name === "tcp" ? root.tcpFailures : root.dnsFailures;
                console.log("[offline-banner] leg down leg=" + name + " failures=" + after + "/" + root.failuresToShow);
                root.emitState();
            }

            // Raw-counter legs computation. CHANGE HANDLERS AND EMITSTATE
            // MUST USE THIS, not the downLegs/degradedLegs/degradedVisible
            // bindings: chained var/computed bindings can still hold stale
            // values mid-cascade (CI-proven 2026-11-09: the state write at
            // the phase flip carried phase=degraded with
            // degradedVisible=false — the journal self-corrects never, the
            // state file only on the NEXT probe, and a poll in between
            // reads the lie).
            function rawDownLegs() {
                const legs = [];
                if (root.failures >= root.failuresToShow) legs.push("icmp");
                if (root.tcpFailures >= root.failuresToShow) legs.push("tcp");
                if (root.dnsFailures >= root.failuresToShow) legs.push("dns");
                return legs;
            }

            onPhaseChanged: {
                // Structured phase lines — DISTINCT tokens from the banner
                // state lines (probe-transitions greps stay exact).
                const legsNow = root.rawDownLegs();
                console.log("[offline-banner] banner phase=" + root.phase + " legs=" + legsNow.join(","));
                // The ledger close lives HERE, on the departure from
                // offline: it is the only point every outage path (icmp,
                // tcp/dns, or both) funnels through. root.offline was
                // still true an instant ago, so this fires exactly once
                // per outage that actually showed.
                if (root.previousPhase === "offline" && root.phase !== "offline" && root.firstFailedAt > 0) {
                    root.rememberOutage(Date.now() / 1000);
                    root.outageProbeFailures = 0;
                }
                root.previousPhase = root.phase;
                root.emitState();
            }
            onDownLegsChanged: {
                // New down-leg composition = a fresh fact: reset dwell AND
                // the degraded dismissal, so the strip re-informs. (The
                // binding only re-evaluates when a leg CROSSES its
                // threshold — plain failure-count creep never fires it,
                // which is what keeps a flapping leg from flashing.)
                root.dwellExpired = false;
                root.dismissedDegraded = false;
                if (root.degradedDwellMs > 0)
                    dwellTimer.restart();
            }

            // Observability (2026-10-17): the journal lines above plus the
            // state file below make a dead or stuck banner visible instead
            // of silent. The file doubles as a freshness heartbeat — it is
            // rewritten on every probe, so an `updatedAt` older than ~2
            // intervals means the unit is effectively dead (fail closed).
            function emitState() {
                // legs/visibility come from rawDownLegs(), NOT the
                // bindings — see the rawDownLegs comment (the CI-proven
                // stale mid-cascade write).
                const legsNow = root.rawDownLegs();
                const degradedVisibleNow = root.phase === "degraded"
                    && !root.dismissedDegraded
                    && !root.dwellExpired;
                stateWrite.command = [
                    "sh", "-c",
                    // Atomic rename (tmp + mv): a plain truncate-write has a
                    // window where readers (waybar polls, the probe-transitions
                    // asserts) see an EMPTY state file — CI-proven x86_64
                    // 2026-11-10. mv within the same directory is rename(2),
                    // so consumers only ever see a complete old or new state.
                    "printf '%s' \"$2\" > \"$1.tmp\" && mv -f \"$1.tmp\" \"$1\"",
                    "offline-banner-state",
                    (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/offline-banner/state",
                    JSON.stringify({
                    active: root.offline && !root.dismissed,
                    demo: root.demo,
                    reason: root.reason,
                    failures: root.failures,
                    failuresToShow: root.failuresToShow,
                    // Outage start (epoch sec) while offline, else null —
                    // the live twin of the ledger's "from"; waybar-style
                    // consumers can show "offline for N" off this.
                    since: root.offline && root.firstFailedAt > 0 ? Math.floor(root.firstFailedAt) : null,
                    // Phase ladder + per-leg detail (2026-11-09). Additive:
                    // every pre-legs key above keeps its name and shape.
                    phase: root.phase,
                    legs: {
                    icmp: { failures: root.failures, down: legsNow.indexOf("icmp") >= 0 },
                    tcp: { failures: root.tcpFailures, down: legsNow.indexOf("tcp") >= 0 },
                    dns: { failures: root.dnsFailures, down: legsNow.indexOf("dns") >= 0 }
                    },
                    degradedLegs: legsNow,
                    degradedVisible: degradedVisibleNow,
                    updatedAt: Math.floor(Date.now() / 1000)
                    })
                ];
                stateWrite.running = true;
            }

            // ONE cue per outage transition, never per probe (see the
            // module header). The wav dir is unit-managed env; the test
            // seam replaces the whole player argv ($1 = event, $2 = wav).
            function playSound(event) {
                if (root.soundTheme === "none")
                    return;
                const override = root.soundOverride;
                const dir = Quickshell.env("OFFLINE_BANNER_SOUNDS");
                if (override.length === 0 && !dir)
                    return;
                const wav = (dir || "") + "/" + root.soundTheme + "-" + event + ".wav";
                soundPlay.command = override.length > 0
                    ? override.concat(["offline-banner-sound", event, wav])
                    : ["pw-play", "--volume", root.soundVolumeArg, wav];
                soundPlay.running = true;
            }

            // Append the completed-outage entry (journal always; the JSONL
            // file only when historyPath is set). mkdir -p tolerates a
            // fresh state dir on first outage after boot.
            function rememberOutage(toEpoch) {
                const from = root.firstFailedAt;
                const duration = Math.max(0, Math.round(toEpoch - from));
                const reasons = root.outageReasons.join(",");
                console.log("[offline-banner] outage ended from=" + Math.floor(from) + " to=" + Math.floor(toEpoch) + " duration=" + duration + "s reasons=" + reasons);
                if (root.historyPath === "")
                    return;
                historyWrite.command = [
                    "sh", "-c",
                    "mkdir -p \"$(dirname \"$1\")\" && printf '%s\n' \"$2\" >> \"$1\"",
                    "offline-banner-history",
                    root.historyPath,
                    JSON.stringify({
                        from: Math.floor(from),
                        to: Math.floor(toEpoch),
                        durationSec: duration,
                        reasons: root.outageReasons,
                        probeFailures: root.outageProbeFailures
                    })
                ];
                historyWrite.running = true;
            }

            onOfflineChanged: {
                // Structured tokens (grep-able: journalctl | grep "banner state=")
                // on top of the prose. At hide time the binding fires on the
                // failures reset, so reason still names the outage being
                // recovered from and failures is already 0.
                root.playSound(root.offline
                    ? "offline-" + (root.reason === "link" ? "link" : "net")
                    : "recover");
                console.log("[offline-banner] banner state=" + (root.offline ? "shown" : "hidden") + " reason=" + root.reason + " failures=" + root.failures + "/" + root.failuresToShow);
                root.emitState();
            }
            onDismissedChanged: {
                if (root.dismissed) {
                    root.playSound("dismiss");
                    console.log("[offline-banner] banner state=dismissed rearm=next_clean_probe");
                }
                root.emitState();
            }

            Process {
                id: probe

                // The virtual-interface exclusion list below is mirrored in
                // SystemNix's wifi-failover QML (SystemNix/modules/nixos/
                // services/wifi-failover.nix) — keep the two lists in sync.
                // OFFLINE_BANNER_SYSROOT (internal, test-only): redirects
                // the carrier glob — the probe-transition test injects a
                // synthetic sysroot instead of needing a real NIC.
                command: root.probeOverride.length > 0 ? root.probeOverride : ["sh", "-c",
                    "link=0; " +
                    "for c in ''${OFFLINE_BANNER_SYSROOT:-/sys}/class/net/*/carrier; do " +
                    "  case \"$c\" in " +
                    "    */lo/*|*/docker*/*|*/br-*/*|*/veth*/*|*/virbr*/*|*/tailscale*/*|*/zt*/*|*/wg*/*|*/tun*/*|*/tap*/*) continue ;; " +
                    "  esac; " +
                    "  read v < \"$c\" 2>/dev/null || v=0; " +
                    "  if [ \"$v\" = \"1\" ]; then link=1; break; fi; " +
                    "done; " +
                    "if [ \"$link\" = \"0\" ]; then echo link; exit 0; fi; " +
                    "if ping -n -c 1 -W \"$OFFLINE_BANNER_PROBE_TIMEOUT\" \"$OFFLINE_BANNER_PROBE_HOST\" >/dev/null 2>&1; then echo ok; else echo net; fi"]
                running: !root.demo

                stdout: StdioCollector {
                    id: probeOut

                    onStreamFinished: root.applyProbe(probeOut.text)
                }
            }

            Process {
                id: netProbe

                // The TCP+DNS legs (2026-11-09). Two output lines, exact
                // format: "tcp ok|fail" then "dns ok|fail". The TCP leg
                // dials an IP literal through bash's /dev/tcp (no resolver
                // in the path); the DNS leg walks getent → glibc/NSS (what
                // applications see). `timeout` (coreutils) caps both — a
                // silently filtered connect would hang forever otherwise,
                // and the probe timeout is the SAME probeTimeoutSeconds
                // the icmp leg uses. OFFLINE_BANNER_NET_PROBE_CMD (test
                // seam) replaces the whole script.
                command: root.netProbeOverride.length > 0 ? root.netProbeOverride : ["sh", "-c",
                    "if timeout \"$OFFLINE_BANNER_PROBE_TIMEOUT\" bash -c 'exec 3<>\"/dev/tcp/$OFFLINE_BANNER_TCP_HOST/$OFFLINE_BANNER_TCP_PORT\"' 2>/dev/null; then echo tcp ok; else echo tcp fail; fi; " +
                    "if timeout \"$OFFLINE_BANNER_PROBE_TIMEOUT\" getent ahostsv4 \"$OFFLINE_BANNER_DNS_NAME\" >/dev/null 2>&1; then echo dns ok; else echo dns fail; fi"]
                running: !root.demo

                stdout: StdioCollector {
                    id: netProbeOut

                    onStreamFinished: root.applyNetProbe(netProbeOut.text)
                }
            }

            Timer {
                interval: root.intervalMs
                running: true
                repeat: true
                triggeredOnStart: true

                onTriggered: {
                    // A still-running probe (ping up to -W timeout, or a
                    // tcp+dns pass up to 2x that) is never stomped; the
                    // next tick catches it instead.
                    if (!root.demo && !probe.running)
                        probe.running = true;
                    if (!root.demo && !netProbe.running)
                        netProbe.running = true;
                }
            }

            // Degraded-strip dwell: the info strip auto-fades after
            // degradedDwellMs unless that is 0 (sticky). Restarted by
            // onDownLegsChanged on every NEW down-leg set.
            Timer {
                id: dwellTimer

                interval: root.degradedDwellMs
                repeat: false
                running: root.phase === "degraded" && root.degradedDwellMs > 0

                onTriggered: root.dwellExpired = true
            }

            // Rewritten by emitState() on every probe and every transition
            // (see the observability note there).
            Process {
                id: stateWrite

                running: false
            }

            // Sound playback (pw-play) or the test-seam override; started
            // at most once per outage transition by playSound().
            Process {
                id: soundPlay

                running: false
            }

            // Outage-ledger appends, started by rememberOutage() on
            // recovery only.
            Process {
                id: historyWrite

                running: false
            }

            // 1 s display tick: re-evaluates the "last online X ago"
            // caption while the banner is visible (QML bindings do not
            // re-run on wall-clock passage by themselves).
            Timer {
                interval: 1000
                running: root.offline
                repeat: true
                triggeredOnStart: true

                onTriggered: root.tick = root.tick + 1
            }

            Variants {
                model: Quickshell.screens

                delegate: PanelWindow {
                    id: banner

                    required property var modelData

                    readonly property int shownHeight: Math.max(52, Math.round(modelData.height * 0.032))
                    // The degraded info strip is deliberately SLIMMER than
                    // the offline alarm: it is an FYI (one leg down,
                    // network still usable), not a warning.
                    readonly property int degradedHeight: Math.max(30, Math.round(modelData.height * 0.02))
                    readonly property bool offlineShown: root.offline && !root.dismissed
                    readonly property bool stripShown: banner.offlineShown || root.degradedVisible
                    // Animated height drives BOTH the surface size and its
                    // exclusive zone (ExclusionMode.Auto): a top-anchored
                    // exclusive bar is repositioned by the compositor on
                    // every animation frame — the slow slide-down; it
                    // slides back up on recovery as the height animates
                    // to 0.
                    property real animHeight: banner.stripShown
                        ? (banner.offlineShown ? banner.shownHeight : banner.degradedHeight)
                        : 0
                    Behavior on animHeight {
                        NumberAnimation {
                            duration: 450
                            easing.type: Easing.InOutCubic
                        }
                    }

                    screen: modelData
                    visible: banner.stripShown || banner.animHeight > 1
                    updatesEnabled: banner.stripShown || banner.animHeight > 1

                    WlrLayershell.namespace: "${cfg.layerNamespace}"
                    WlrLayershell.layer: WlrLayer.Top
                    WlrLayershell.exclusionMode: ExclusionMode.Auto

                    anchors {
                        top: true
                        left: true
                        right: true
                    }

                    implicitHeight: banner.animHeight
                    color: "transparent"

                    Rectangle {
                        anchors.fill: parent
                        // Yellow = offline alarm (the doctrine); info-blue
                        // = degraded (a leg down, network still usable).
                        // The blue is chosen far outside render-smoke's
                        // banner-yellow pixel range on purpose.
                        color: banner.offlineShown ? "#f2f9e2af" : "#dbe4f2af"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                if (banner.offlineShown)
                                    root.dismissed = true;
                                else
                                    root.dismissedDegraded = true;
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: banner.offlineShown
                                    ? "⚠  OFFLINE — " + root.reasonText
                                    : "⚠  DEGRADED — " + root.degradedText
                                color: "#1e1e2e"
                                font.pixelSize: Math.max(13, Math.round(modelData.height * (banner.offlineShown ? 0.012 : 0.009)))
                                font.weight: Font.Black
                                font.letterSpacing: 2
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: banner.offlineShown
                                    ? "last online " + root.lastOnlineAgo + " ago  ·  click to dismiss"
                                    : "other legs up — network still usable  ·  click to dismiss"
                                color: "#1e1e2e"
                                opacity: 0.75
                                font.pixelSize: Math.max(10, Math.round(modelData.height * 0.006))
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }
        }
      '';

      # Sound-event semantics (the audible doctrine; mirrors the QML
      # triggers in playSound): offline-net = two-note droop, offline-link
      # = the same droop LOWER (link loss is the heavier failure — pitch,
      # not loudness, carries it), recover = ascending sparkle, dismiss =
      # near-inaudible tick. Synthesis: pure stdlib (wave/struct/math), no
      # assets, no fetch — 3 themes x 4 events, each < 1 s mono 16-bit.
      genSoundsScript = pkgs.writeText "gen-offline-banner-sounds.py" ''
        import math
        import os
        import struct
        import sys
        import wave

        SR = 44100

        def note(start, dur, f0, f1=None, amp=0.5, kind="sine", att=0.010, rel=0.060):
            return (start, dur, kind, f0, f0 if f1 is None else f1, amp, att, rel)

        def render(path, notes, gain):
            total = int((max(s + d for s, d, *_ in notes) + 0.02) * SR) + 1
            buf = [0.0] * total
            for start, dur, kind, f0, f1, amp, att, rel in notes:
                n0, n1 = int(start * SR), int((start + dur) * SR)
                span = max(1, n1 - n0)
                phase = 0.0
                for i in range(n0, n1):
                    t = (i - n0) / span
                    f = f0 + (f1 - f0) * t
                    phase += 2.0 * math.pi * f / SR
                    s = math.sin(phase)
                    if kind == "square":
                        s = 1.0 if s >= 0.0 else -1.0
                    env = min(1.0, (i - n0) / max(1.0, att * SR)) * min(1.0, (n1 - i) / max(1.0, rel * SR))
                    buf[i] += s * env * amp
            peak = max(abs(x) for x in buf) or 1.0
            scale = gain / peak
            frames = bytearray()
            for x in buf:
                v = int(max(-1.0, min(1.0, x * scale)) * 32767.0)
                frames += struct.pack("<h", v)
            with wave.open(path, "wb") as w:
                w.setnchannels(1)
                w.setsampwidth(2)
                w.setframerate(SR)
                w.writeframes(bytes(frames))

        THEMES = {
            "chime": (0.50, {
                "offline-net": [
                    note(0.00, 0.14, 392.00),
                    note(0.15, 0.24, 261.63, amp=0.45, rel=0.10),
                ],
                "offline-link": [
                    note(0.00, 0.14, 329.63),
                    note(0.15, 0.28, 196.00, amp=0.50, rel=0.12),
                ],
                "recover": [
                    note(0.00, 0.09, 523.25),
                    note(0.10, 0.09, 659.26),
                    note(0.20, 0.16, 783.99, amp=0.55, rel=0.10),
                ],
                "dismiss": [note(0.00, 0.07, 261.63, amp=0.50)],
            }),
            "droplet": (0.45, {
                "offline-net": [note(0.00, 0.16, 880.00, 392.00)],
                "offline-link": [note(0.00, 0.22, 493.88, 174.61)],
                "recover": [
                    note(0.00, 0.09, 392.00, 783.99),
                    note(0.11, 0.14, 523.25, 1046.50, amp=0.55),
                ],
                "dismiss": [note(0.00, 0.06, 659.26, 493.88)],
            }),
            "retro": (0.35, {
                "offline-net": [
                    note(0.00, 0.09, 493.88, kind="square"),
                    note(0.10, 0.09, 415.30, kind="square"),
                    note(0.20, 0.13, 349.23, kind="square"),
                ],
                "offline-link": [note(0.00, 0.28, 392.00, 98.00, kind="square")],
                "recover": [
                    note(0.00, 0.07, 329.63, kind="square"),
                    note(0.08, 0.07, 440.00, kind="square"),
                    note(0.16, 0.07, 554.37, kind="square"),
                    note(0.24, 0.13, 659.26, kind="square"),
                ],
                "dismiss": [note(0.00, 0.05, 220.00, kind="square")],
            }),
        }

        out = sys.argv[1]
        for theme, (gain, events) in THEMES.items():
            for event, notes in events.items():
                render(os.path.join(out, theme + "-" + event + ".wav"), notes, gain)
        print("offline-banner: synthesized %d sounds" % sum(len(e) for _, e in THEMES.values()))
      '';

      offlineBannerSounds =
        pkgs.runCommand "offline-banner-sounds"
          {
            nativeBuildInputs = [ pkgs.python3 ];
          }
          ''
            mkdir -p "$out"
            python3 ${genSoundsScript} "$out"
            # Build-time self-check: the full 3x4 matrix landed.
            got=$(ls "$out" | wc -l)
            [ "$got" -eq 12 ] || { echo "FAIL: expected 12 synthesized sounds, got $got"; exit 1; }
          '';

      # The ledger's parent dir must be PROVISIONED by the unit, not merely
      # bound: ReadWritePaths cannot create a missing directory (2026-11-05
      # evo-x2 live incident — the deployed unit died at NAMESPACE setup,
      # status 226, in a restart loop until the start limit, and the banner
      # was silently absent through every outage). Exactly two parent shapes
      # are provisioned: %h/.local/state/<name> (this leaf, via
      # StateDirectory=) and %t/offline-banner (via the unconditional
      # RuntimeDirectory=). Anything else fails eval with the assertion
      # below instead of dying silently at runtime.
      ledgerStateDirLeaf =
        let
          m = builtins.match "%h/\\.local/state/([^/]+)" (dirOf cfg.historyPath);
        in
        if m == null then null else builtins.head m;

      # Writability derives from provisioning (single source of truth):
      # every ReadWritePaths hole is computed from a dir the unit
      # PROVISIONS — RuntimeDirectory for the %t side, StateDirectory for
      # the %h side — so a hole can no longer drift away from its
      # provisioner (the 2026-11-05 incident was exactly a hole whose dir
      # nothing created). module-contract additionally computes the
      # every-hole-is-provisioned invariant over the rendered config.
      provisionedRuntimeDirs = [
        "offline-banner"
        "quickshell"
      ];
      provisionedStateDirs = lib.optionals (cfg.enableHistory && ledgerStateDirLeaf != null) [
        ledgerStateDirLeaf
      ];
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.probeTimeoutSeconds < cfg.checkIntervalSeconds;
          message = "services.offline-banner: probeTimeoutSeconds (${toString cfg.probeTimeoutSeconds}) must be < checkIntervalSeconds (${toString cfg.checkIntervalSeconds}) or probes overlap";
        }
        {
          assertion = cfg.failuresToShow <= 10;
          message = "services.offline-banner: failuresToShow (${toString cfg.failuresToShow}) exceeds 10 — the banner would stay hidden for over a minute at defaults; a value this high is a typo, not a debounce";
        }
        {
          assertion =
            !cfg.enableHistory || lib.hasPrefix "/" cfg.historyPath || lib.hasPrefix "%" cfg.historyPath;
          message = "services.offline-banner: historyPath (\"${toString cfg.historyPath}\") must be absolute — a leading %h/%t systemd specifier is fine";
        }
        {
          assertion =
            !cfg.enableHistory || ledgerStateDirLeaf != null || dirOf cfg.historyPath == "%t/offline-banner";
          message = ''
            services.offline-banner: historyPath's parent ("${dirOf cfg.historyPath}") is not a directory the unit provisions — use %h/.local/state/<name> (created via StateDirectory=) or %t/offline-banner (created via RuntimeDirectory=).
            ReadWritePaths cannot create a missing directory: an unprovisioned parent kills the unit at NAMESPACE setup (status 226) in a restart loop, and the banner never shows at all (2026-11-05 evo-x2 outage).
          '';
        }
      ];

      systemd.user.services.offline-banner = {
        description = "Yellow offline banner on all monitors (Quickshell layer-shell)";
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];

        environment = {
          OFFLINE_BANNER_INTERVAL = toString (cfg.checkIntervalSeconds * 1000);
          OFFLINE_BANNER_PROBE_HOST = cfg.probeHost;
          OFFLINE_BANNER_PROBE_TIMEOUT = toString cfg.probeTimeoutSeconds;
          OFFLINE_BANNER_FAILURES = toString cfg.failuresToShow;
          # TCP/DNS legs (2026-11-09): same env-contract doctrine as the
          # four vars above — drop-in retunable, asserted by
          # module-contract, inert-safe defaults in the QML.
          OFFLINE_BANNER_TCP_HOST = cfg.tcpProbeHost;
          OFFLINE_BANNER_TCP_PORT = toString cfg.tcpProbePort;
          OFFLINE_BANNER_DNS_NAME = cfg.dnsProbeName;
          OFFLINE_BANNER_DEGRADED_DWELL = toString cfg.degradedDwellSeconds;
          # fontconfig/Qt cache under the sandbox: ProtectSystem=strict +
          # ProtectHome=read-only make $HOME/.cache unwritable (live smoke
          # showed fontconfig cache-write warnings). %t expands in unit-file
          # Environment= (config_parse_environ specifier table); the cache/
          # subdir is created by the apps — the state file stays untouched
          # beside it.
          XDG_CACHE_HOME = "%t/offline-banner/cache";
          # mkForce: systemd's user-unit default PATH is also set via
          # environment.PATH and would collide (eval-hard error). The
          # probes are shell builtins + ping (iputils, cap_net_raw) +
          # `timeout` (coreutils) + `getent` (glibc) for the tcp/dns legs;
          # bash provides sh. pw-play (pipewire) joins only when a sound
          # theme is on; it talks to the session PipeWire over its AF_UNIX
          # socket (already allowed).
          PATH = lib.mkForce (
            lib.makeBinPath (
              [
                pkgs.bash
                pkgs.coreutils
                pkgs.glibc
                pkgs.iputils
              ]
              ++ lib.optionals (cfg.soundTheme != "none") [ pkgs.pipewire ]
            )
          );
        }
        // (
          # Sounds: same env-contract doctrine as the probe vars. The wav
          # dir is a store path (same derivation as restartTriggers — a
          # re-synthesis restarts the unit). Unset when theme = "none", so
          # bare env inspection tells sound-enabled units apart.
          lib.optionalAttrs (cfg.soundTheme != "none") {
            OFFLINE_BANNER_SOUND_THEME = cfg.soundTheme;
            OFFLINE_BANNER_SOUND_VOLUME = toString cfg.soundVolume;
            OFFLINE_BANNER_SOUNDS = toString offlineBannerSounds;
          }
        )
        // (
          # Outage ledger: %h expands like %t above; ReadWritePaths below
          # opens the matching writable hole under the read-only home.
          # Unset when history is disabled — the QML then never writes.
          lib.optionalAttrs cfg.enableHistory {
            OFFLINE_BANNER_HISTORY = cfg.historyPath;
          }
        );

        restartTriggers = [
          offlineBannerShell
          offlineBannerSounds
        ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe cfg.package} -p ${offlineBannerShell}";
          Restart = "always";
          RestartSec = "5s";
          MemoryMax = "256M";

          # Sandbox (2026-10-16): the banner reads /sys, pings, and talks
          # Wayland — nothing else. NoNewPrivileges is deliberately ABSENT:
          # it ignores iputils' cap_net_raw file capability (the design the
          # probe relies on, see header) and turns every ping into a silent
          # permission failure → permanent "net" state. The same live-only
          # risk withholds PrivateDevices (GPU /dev/dri), MemoryDenyWrite
          # Execute (QML JIT) and SystemCallFilter; rendering is not CI-
          # testable (see AGENTS.md) — extend only with live-verified options.
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          PrivateTmp = true;
          # strict makes /run/user read-only; the unit needs exactly two
          # dirs there: quickshell's own runtime layout and the banner
          # state dir (live-verified 2026-10-17 — without this the unit
          # runs but quickshell cannot create its runtime dirs).
          RuntimeDirectory = provisionedRuntimeDirs;
          RuntimeDirectoryMode = "0700";
          # The outage ledger is PERSISTENT (survives reboots — that is
          # its point), so it cannot live in the volatile runtime dir:
          # exactly its parent dir under the read-only home becomes the
          # unit's one home write hole (%h expands in this setting like
          # %t above). Both holes are DERIVED from the provisioned dirs
          # above — %t/<dir> from RuntimeDirectory, %h/.local/state/<dir>
          # from StateDirectory — so this list cannot name a dir the unit
          # does not create.
          ReadWritePaths =
            map (d: "%t/${d}") provisionedRuntimeDirs ++ map (s: "%h/.local/state/${s}") provisionedStateDirs;
          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
          ];
          RestrictNamespaces = true;
          LockPersonality = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          ProtectClock = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          ProtectProc = "invisible";
          SystemCallArchitectures = "native";
        }
        // lib.optionalAttrs (cfg.enableHistory && ledgerStateDirLeaf != null) {
          # Provision the ledger dir BEFORE the mount namespace is applied:
          # ReadWritePaths binds but never creates (2026-11-05 evo-x2: a
          # missing ~/.local/state/offline-banner failed namespacing at
          # status 226, the restart loop hit the start limit, and the
          # banner was silently absent through every outage). User units
          # root StateDirectory at ~/.local/state (live-verified on
          # systemd 261: created 0700, writable under ProtectHome). The
          # ReadWritePaths hole is DERIVED from this same list (see
          # provisionedStateDirs) — writability statement and provisioner
          # cannot drift apart, and module-contract pins both sides.
          StateDirectory = provisionedStateDirs;
          StateDirectoryMode = "0700";
        };

        unitConfig = {
          StartLimitBurst = 5;
          StartLimitIntervalSec = 120;
        };
      };
    };
}
