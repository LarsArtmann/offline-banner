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
                    root.lastOnlineAt = Date.now() / 1000;
                    root.dismissed = false;
                    root.failures = 0;
                    root.reason = "";
                    root.emitState();
                    return;
                }
                // "link" = carrier gone; "net" = link up, probe host
                // unreachable; anything else = the probe itself failed
                // to run — all three keep the banner honest.
                root.reason = result === "link" ? "link" : "net";
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
                        updatedAt: Math.floor(Date.now() / 1000)
                    })
                ];
                stateWrite.running = true;
            }

            onOfflineChanged: {
                // Structured tokens (grep-able: journalctl | grep "banner state=")
                // on top of the prose. At hide time the binding fires on the
                // failures reset, so reason still names the outage being
                // recovered from and failures is already 0.
                console.log("[offline-banner] banner state=" + (root.offline ? "shown" : "hidden") + " reason=" + root.reason + " failures=" + root.failures + "/" + root.failuresToShow);
                root.emitState();
            }
            onDismissedChanged: {
                if (root.dismissed)
                    console.log("[offline-banner] banner state=dismissed rearm=next_clean_probe");
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
          # iputils' ping ships cap_net_raw.
          PATH = lib.mkForce (
            lib.makeBinPath [
              pkgs.bash
              pkgs.iputils
            ]
          );
        };

        restartTriggers = [ offlineBannerShell ];

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
