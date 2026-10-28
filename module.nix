# Yellow top-strip banner (Quickshell layer-shell) while the desktop is offline.
#
# What "offline" means here and why the probe is NOT `nmcli networking
# connectivity`: NetworkManager often manages WiFi only — a static-IP
# ethernet uplink is NM-unmanaged and NM's connectivity state reads "none"
# even while the internet is perfectly reachable (live-verified on the
# origin host 2026-10-16). The probe is a two-leg check instead:
#   1. any real interface (lo/veth/tailscale/wg/... excluded) with carrier 1
#      — else "link" (cable out / wifi dead);
#   2. an ICMP echo to the probe host (default 9.9.9.9) — else "net"
#      (router up, WAN down). An IP, not a name: DNS can be half-broken
#      exactly when the banner matters, and coupling the banner to the
#      resolver would blackhole it then.
# `ping` needs no wrapper on NixOS (nixpkgs iputils ships cap_net_raw).
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
      description = "Consecutive failed probes before the banner appears (debounce)";
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
      description = "Absolute path of the persistent outage log (JSON Lines). %h/%t systemd unit specifiers expand (in unit-file Environment= and ReadWritePaths); the parent directory becomes the unit's only writable path under the read-only home";
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
            readonly property bool offline: root.demo || root.failures >= root.failuresToShow
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
                    // Close the outage ledger entry BEFORE the resets below
                    // consume it — root.offline is still true here (the
                    // binding re-evaluates on the failures reset after this
                    // function returns), so this fires exactly once per
                    // outage that actually showed.
                    if (root.offline && root.firstFailedAt > 0)
                        root.rememberOutage(Date.now() / 1000);
                    root.lastOnlineAt = Date.now() / 1000;
                    root.dismissed = false;
                    root.failures = 0;
                    root.reason = "";
                    root.firstFailedAt = 0;
                    root.outageReasons = [];
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
                console.log("[offline-banner] probe failed reason=" + root.reason + " failures=" + root.failures + "/" + root.failuresToShow);
                root.emitState();
            }

            // Observability (2026-10-17): the journal lines above plus the
            // state file below make a dead or stuck banner visible instead
            // of silent. The file doubles as a freshness heartbeat — it is
            // rewritten on every probe, so an `updatedAt` older than ~2
            // intervals means the unit is effectively dead (fail closed).
            function emitState() {
                stateWrite.command = [
                    "sh", "-c",
                    "printf '%s' \"$2\" > \"$1\"",
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
                        probeFailures: root.failures
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

            Timer {
                interval: root.intervalMs
                running: true
                repeat: true
                triggeredOnStart: true

                onTriggered: {
                    // A still-running probe (ping up to -W timeout) is
                    // never stomped; the next tick catches it instead.
                    if (!root.demo && !probe.running)
                        probe.running = true;
                }
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
                    // Animated height drives BOTH the surface size and its
                    // exclusive zone (ExclusionMode.Auto): a top-anchored
                    // exclusive bar is repositioned by the compositor on
                    // every animation frame — the slow slide-down; it
                    // slides back up on recovery as the height animates
                    // to 0.
                    property real animHeight: (root.offline && !root.dismissed) ? banner.shownHeight : 0
                    Behavior on animHeight {
                        NumberAnimation {
                            duration: 450
                            easing.type: Easing.InOutCubic
                        }
                    }

                    screen: modelData
                    visible: (root.offline && !root.dismissed) || banner.animHeight > 1
                    updatesEnabled: (root.offline && !root.dismissed) || banner.animHeight > 1

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
                        color: "#f2f9e2af"

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.dismissed = true
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "⚠  OFFLINE — " + root.reasonText
                                color: "#1e1e2e"
                                font.pixelSize: Math.max(15, Math.round(modelData.height * 0.012))
                                font.weight: Font.Black
                                font.letterSpacing: 2
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "last online " + root.lastOnlineAgo + " ago  ·  click to dismiss"
                                color: "#1e1e2e"
                                opacity: 0.75
                                font.pixelSize: Math.max(11, Math.round(modelData.height * 0.007))
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

      offlineBannerSounds = pkgs.runCommand "offline-banner-sounds"
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
          assertion = !cfg.enableHistory || lib.hasPrefix "/" cfg.historyPath || lib.hasPrefix "%" cfg.historyPath;
          message = "services.offline-banner: historyPath (\"${toString cfg.historyPath}\") must be absolute — a leading %h/%t systemd specifier is fine";
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
          # fontconfig/Qt cache under the sandbox: ProtectSystem=strict +
          # ProtectHome=read-only make $HOME/.cache unwritable (live smoke
          # showed fontconfig cache-write warnings). %t expands in unit-file
          # Environment= (config_parse_environ specifier table); the cache/
          # subdir is created by the apps — the state file stays untouched
          # beside it.
          XDG_CACHE_HOME = "%t/offline-banner/cache";
          # mkForce: systemd's user-unit default PATH is also set via
          # environment.PATH and would collide (eval-hard error). The
          # probe is pure shell builtins + ping — bash provides sh,
          # iputils' ping ships cap_net_raw. pw-play (pipewire) joins
          # only when a sound theme is on; it talks to the session
          # PipeWire over its AF_UNIX socket (already allowed).
          PATH = lib.mkForce (
            lib.makeBinPath (
              [
                pkgs.bash
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
          RuntimeDirectory = [
            "offline-banner"
            "quickshell"
          ];
          RuntimeDirectoryMode = "0700";
          ReadWritePaths = [
            "%t/quickshell"
            "%t/offline-banner"
          ]
          # The outage ledger is PERSISTENT (survives reboots — that is
          # its point), so it cannot live in the volatile runtime dir:
          # exactly its parent dir under the read-only home becomes the
          # unit's one home write hole (%h expands in this setting like
          # %t above).
          ++ lib.optionals cfg.enableHistory [
            (dirOf cfg.historyPath)
          ];
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
        };

        unitConfig = {
          StartLimitBurst = 5;
          StartLimitIntervalSec = 120;
        };
      };
    };
}
