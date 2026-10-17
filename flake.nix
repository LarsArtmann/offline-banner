{
  description = "offline-banner: yellow top-strip banner for NixOS desktops while offline (Quickshell layer-shell)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      treefmt-nix,
      self,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      treefmtEval = forAllSystems (
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} (_: {
          programs = {
            nixfmt.enable = true;
            statix.enable = true;
          };
          projectRootFile = "flake.nix";
        })
      );

      offlineBannerModule = import ./module.nix;

      evalModule =
        system: extraModules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ offlineBannerModule ] ++ extraModules;
        };
    in
    {
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          enabled = evalModule system [ { services.offline-banner.enable = true; } ];
          disabled = evalModule system [ ];
          unit = enabled.config.systemd.user.units."offline-banner.service";
          # Assertions are tested in ISOLATION (lib.evalModules with only our
          # module): a full nixosSystem eval carries ~1.4k base assertions,
          # several with messages that throw when forced — count-total there
          # would stay green even if OUR assertion vanished.
          standaloneAssertions =
            settings:
            (nixpkgs.lib.evalModules {
              modules = [
                # The `assertions` and `systemd.user.services` options are
                # declared by NixOS base modules, absent from a bare
                # module-system eval — stub them (loose types; we only
                # inspect the merged values).
                {
                  options = {
                    assertions = nixpkgs.lib.mkOption {
                      type = nixpkgs.lib.types.listOf nixpkgs.lib.types.attrs;
                      default = [ ];
                      internal = true;
                      visible = false;
                    };
                    systemd.user.services = nixpkgs.lib.mkOption {
                      type = nixpkgs.lib.types.attrs;
                      default = { };
                      internal = true;
                      visible = false;
                    };
                  };
                }
                offlineBannerModule
                { services.offline-banner = settings; }
              ];
              specialArgs.pkgs = pkgs;
            }).config.assertions;
          failing = nixpkgs.lib.filter (a: !a.assertion);
          badStandaloneAsserts = nixpkgs.lib.length (
            failing (standaloneAssertions {
              enable = true;
              checkIntervalSeconds = 2;
              probeTimeoutSeconds = 5;
            })
          );
          goodStandaloneAsserts = nixpkgs.lib.length (
            failing (standaloneAssertions {
              enable = true;
            })
          );
        in
        {
          formatting = treefmtEval.${system}.config.build.check self;
          module-contract =
            pkgs.runCommand "offline-banner-module-contract"
              {
                unitPresent = toString (enabled.config.systemd.user.units ? "offline-banner.service");
                unitAbsent = toString (!(disabled.config.systemd.user.units ? "offline-banner.service"));
                quickshellInExecStart = toString (nixpkgs.lib.hasInfix "quickshell" unit.text);
                envContractInUnit = toString (
                  nixpkgs.lib.all (var: nixpkgs.lib.hasInfix var unit.text) [
                    "OFFLINE_BANNER_INTERVAL"
                    "OFFLINE_BANNER_PROBE_HOST"
                    "OFFLINE_BANNER_PROBE_TIMEOUT"
                    "OFFLINE_BANNER_FAILURES"
                  ]
                );
                memoryMaxSet = toString (nixpkgs.lib.hasInfix "MemoryMax" unit.text);
                # Writable cache under the sandbox: the unit must point the
                # XDG cache at the runtime dir (specifiers DO expand in
                # unit-file Environment=), or fontconfig/Qt spams read-only
                # $HOME/.cache warnings under ProtectSystem=strict.
                cacheDirSet = toString (nixpkgs.lib.hasInfix "XDG_CACHE_HOME=%t/offline-banner/cache" unit.text);
                # The FULL sandbox contract: every hardening directive the
                # unit must carry (a refactor dropping one line fails this).
                # List options render one line per item in unit text.
                sandboxInUnit = toString (
                  nixpkgs.lib.all (line: nixpkgs.lib.hasInfix line unit.text) [
                    "ProtectSystem=strict"
                    "ProtectHome=read-only"
                    "PrivateTmp=true"
                    "RestrictAddressFamilies=AF_UNIX"
                    "RestrictAddressFamilies=AF_INET"
                    "RestrictAddressFamilies=AF_INET6"
                    "RestrictAddressFamilies=AF_NETLINK"
                    "RestrictNamespaces=true"
                    "LockPersonality=true"
                    "RestrictRealtime=true"
                    "RestrictSUIDSGID=true"
                    "ProtectClock=true"
                    "ProtectHostname=true"
                    "ProtectKernelLogs=true"
                    "ProtectKernelModules=true"
                    "ProtectKernelTunables=true"
                    "ProtectControlGroups=true"
                    "ProtectProc=invisible"
                    "SystemCallArchitectures=native"
                    "RuntimeDirectory=offline-banner"
                    "RuntimeDirectory=quickshell"
                    "RuntimeDirectoryMode=0700"
                    "ReadWritePaths=%t/quickshell"
                    "ReadWritePaths=%t/offline-banner"
                  ]
                );
                # Deliberate absence: NoNewPrivileges would strip ping's
                # cap_net_raw file capability (see module.nix serviceConfig).
                noNoNewPrivileges = toString (!(nixpkgs.lib.hasInfix "NoNewPrivileges" unit.text));
                # Rename drift: the service must keep restarting on QML
                # changes via a store path that actually holds shell.qml.
                restartTriggersStoreQml = toString (
                  let
                    trigs = enabled.config.systemd.user.services.offline-banner.restartTriggers or [ ];
                  in
                  nixpkgs.lib.length trigs == 1 && nixpkgs.lib.hasInfix "shell.qml" (toString (builtins.head trigs))
                );
                badProbeOverlapAsserts = toString badStandaloneAsserts;
                goodProbeOverlapAsserts = toString goodStandaloneAsserts;
              }
              ''
                [ "$unitPresent" = "1" ] || { echo "FAIL: unit missing when enabled"; exit 1; }
                [ "$unitAbsent" = "1" ] || { echo "FAIL: unit present when disabled"; exit 1; }
                [ "$quickshellInExecStart" = "1" ] || { echo "FAIL: ExecStart does not use quickshell"; exit 1; }
                [ "$envContractInUnit" = "1" ] || { echo "FAIL: OFFLINE_BANNER_* env contract missing from the unit"; exit 1; }
                [ "$memoryMaxSet" = "1" ] || { echo "FAIL: MemoryMax missing"; exit 1; }
                [ "$cacheDirSet" = "1" ] || { echo "FAIL: XDG_CACHE_HOME must point at the runtime dir (fontconfig cache under strict sandbox)"; exit 1; }
                [ "$sandboxInUnit" = "1" ] || { echo "FAIL: sandbox hardening missing from the unit"; exit 1; }
                [ "$noNoNewPrivileges" = "1" ] || { echo "FAIL: NoNewPrivileges must stay unset (it strips cap_net_raw from ping)"; exit 1; }
                [ "$restartTriggersStoreQml" = "1" ] || { echo "FAIL: restartTriggers must reference the store QML (rename drift)"; exit 1; }
                [ "$badProbeOverlapAsserts" -ge 1 ] || { echo "FAIL: probeTimeout >= checkInterval must assert"; exit 1; }
                [ "$goodProbeOverlapAsserts" = "0" ] || { echo "FAIL: probe-overlap assertion fires on a valid config"; exit 1; }
                touch "$out"
              '';
          # Unit-syntax gate: systemd-analyze verify on the rendered unit —
          # catches pin-class typos in serviceConfig mechanically (proven:
          # a bad unit exits 1 with precise diagnostics, the real unit is
          # clean). Sandbox recipe, live-tested 2026-10-17: the build env
          # has no /run, so an LD_PRELOAD shim redirects mkdir/mkdirat of
          # /run/* into the build dir; --user + --recursive-errors=no
          # verifies THIS unit's syntax and ExecStart (dep closure stubbed
          # via the graphical-session.target stub beside it).
          unit-verify =
            pkgs.runCommand "offline-banner-unit-verify"
              {
                nativeBuildInputs = [
                  pkgs.stdenv.cc
                  pkgs.systemd
                ];
                buildInputs = [
                  enabled.config.services.offline-banner.package
                  pkgs.bash
                  pkgs.iputils
                ];
                unitText = enabled.config.systemd.user.units."offline-banner.service".text;
                passAsFile = [ "unitText" ];
              }
              ''
                                cp "$unitTextPath" ./offline-banner.service
                                { echo "[Unit]"; echo "Description=verify dep stub"; } > graphical-session.target
                                cat > fakerun.c <<'CSHIM'
                #define _GNU_SOURCE
                #include <dlfcn.h>
                #include <stdio.h>
                #include <errno.h>
                #include <stdlib.h>
                #include <string.h>
                #include <sys/stat.h>

                static const char *FAKE;

                static char *rewrite(const char *path) {
                    if (!path) return NULL;
                    if (strncmp(path, "/run/", 5) == 0) {
                        static char buf[4096];
                        snprintf(buf, sizeof buf, "%s/%s", FAKE, path + 5);
                        return buf;
                    }
                    if (strcmp(path, "/run") == 0) return (char *)FAKE;
                    return NULL;
                }

                static int mkdirp_fake(const char *r, mode_t mode) {
                    char tmp[4096];
                    snprintf(tmp, sizeof tmp, "%s", r);
                    for (char *p = tmp + 1; *p; p++)
                        if (*p == '/') { *p = 0; mkdir(tmp, 0755); *p = '/'; }
                    int rc = mkdir(tmp, mode);
                    if (rc < 0 && errno == EEXIST) rc = 0;
                    return rc;
                }

                int mkdir(const char *path, mode_t mode) {
                    static int (*real_mkdir)(const char *, mode_t);
                    if (!real_mkdir) real_mkdir = dlsym(RTLD_NEXT, "mkdir");
                    if (!FAKE) { const char *e = getenv("FAKE_RUN"); FAKE = e ? e : "./fakerun"; }
                    const char *r = rewrite(path);
                    return r ? mkdirp_fake(r, mode) : real_mkdir(path, mode);
                }

                int mkdirat(int dirfd, const char *path, mode_t mode) {
                    static int (*real_mkdirat)(int, const char *, mode_t);
                    if (!real_mkdirat) real_mkdirat = dlsym(RTLD_NEXT, "mkdirat");
                    if (!FAKE) { const char *e = getenv("FAKE_RUN"); FAKE = e ? e : "./fakerun"; }
                    const char *r = rewrite(path);
                    if (!r) return real_mkdirat(dirfd, path, mode);
                    (void)dirfd;
                    return mkdirp_fake(r, mode);
                }
                CSHIM
                                cc -shared -fPIC -o fakerun.so fakerun.c -ldl
                                export FAKE_RUN="$PWD/fakerun"
                                export LD_PRELOAD="$PWD/fakerun.so"
                                export XDG_RUNTIME_DIR="$PWD/fakerun"
                                mkdir -p "$XDG_RUNTIME_DIR"
                                if systemd-analyze verify --user --recursive-errors=no --man=no ./offline-banner.service >verify.log 2>&1; then
                                  touch "$out"
                                else
                                  echo "FAIL: systemd-analyze verify rejected the unit:" >&2
                                  cat verify.log >&2
                                  exit 1
                                fi
              '';
          # Probe-transition test (T13): drives the REAL store QML's probe
          # state machine through ok/net/link transitions via
          # OFFLINE_BANNER_PROBE_CMD injection, inside a headless sway
          # compositor (software rendering, no GPU, no network). Asserts,
          # through the journal-fed state file: debounce (failuresToShow),
          # reason semantics (net vs link), recovery, re-arm. Rendering
          # itself stays out of scope (no pixel assertions).
          probe-transitions =
            let
              # The store QML, via restartTriggers (same derivation the unit
              # runs) — as a build input it is REALIZED in-sandbox (an
              # ExecStart path parse alone would reference an unrealized
              # store path and quickshell would refuse it).
              qmlDir = builtins.elemAt enabled.config.systemd.user.services.offline-banner.restartTriggers 0;
            in
            pkgs.runCommand "offline-banner-probe-transitions"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.jq
                  pkgs.quickshell
                  pkgs.sway
                  pkgs.dbus
                  pkgs.coreutils
                  pkgs.gnugrep
                  pkgs.gnused
                ];
                inherit qmlDir;
              }
              ''
                export XDG_RUNTIME_DIR="$PWD/runtime"
                export HOME="$PWD/home"
                export XDG_CACHE_HOME="$HOME/cache"
                mkdir -p "$XDG_CACHE_HOME"
                export QT_QUICK_BACKEND=software
                export QT_QPA_PLATFORM=wayland
                # sway's wrapper would start a session bus via
                # dbus-run-session; the sandbox has no dbus config, and the
                # headless backend does not need one — point the env at a
                # dead path so the wrapper skips it.
                export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
                mkdir -p "$XDG_RUNTIME_DIR"

                echo "output HEADLESS-1 mode 1280x800 position 0,0" > sway-config
                WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman \
                  sway --unsupported-gpu -c sway-config >sway.log 2>&1 &
                sway_pid=$!
                sock=""
                for i in $(seq 1 100); do
                  sock=$(ls "$XDG_RUNTIME_DIR" 2>/dev/null | grep -E '^wayland-[0-9]+$' | head -1 || true)
                  [ -n "$sock" ] && break
                  sleep 0.1
                done
                [ -n "$sock" ] || { echo "FAIL: headless sway did not start"; cat sway.log; exit 1; }
                export WAYLAND_DISPLAY="$sock"
                sleep 0.5

                mkdir -p "$XDG_RUNTIME_DIR/offline-banner"   # the real unit gets this via RuntimeDirectory=
                echo ok > control
                export OFFLINE_BANNER_INTERVAL=600
                export OFFLINE_BANNER_FAILURES=2
                export OFFLINE_BANNER_PROBE_CMD="cat $PWD/control"
                quickshell -p "$qmlDir" >qs.log 2>&1 &
                qs_pid=$!

                state="$XDG_RUNTIME_DIR/offline-banner/state"
                # assert_state EXPECTED_ACTIVE [EXPECTED_REASON] POLL_ROUNDS
                assert_state() {
                  local want="$1" want_reason="''${2:-}" rounds="''${3:-20}" i got json
                  for i in $(seq 1 "$rounds"); do
                    if [ -f "$state" ]; then
                      json=$(cat "$state" 2>/dev/null || echo "{}")
                      got=$(echo "$json" | jq -r '.active | tostring' 2>/dev/null || true)
                      if [ "$got" = "$want" ]; then
                        if [ -n "$want_reason" ]; then
                          if [ "$(echo "$json" | jq -r '.reason | if . == null then "" else . end')" = "$want_reason" ]; then return 0; fi
                        else
                          return 0
                        fi
                      fi
                    fi
                    sleep 0.3
                  done
                  echo "FAIL: expected active=$want''${want_reason:+ reason=$want_reason}, last state: $(cat "$state" 2>/dev/null || echo MISSING)" >&2
                  echo "--- qs.log ---" >&2; tail -20 qs.log >&2
                  exit 1
                }

                # Journal asserts: quickshell's console.log lands in the log
                # files (stderr), one structured line per transition.
                # POLLING (not a one-shot grep): the state-file asserts can
                # return on a pre-existing state before the triggering probe
                # has even run, so the matching line may lag a few hundred ms
                # (grep -F: the patterns contain = and /).
                assert_journal() {
                  local pattern="$1" f="''${2:-qs.log}" i
                  for i in $(seq 1 40); do
                    grep -qF -- "$pattern" "$f" && return 0
                    sleep 0.25
                  done
                  echo "FAIL: journal line '$pattern' not found in $f" >&2
                  tail -20 "$f" >&2
                  exit 1
                }
                # Regex twin of assert_journal for mid-sequence counter
                # asserts: extra probes fire while the shell is between
                # statements (600 ms cadence, slow emulated runners), so
                # exact failure counts are only deterministic at positions
                # reachable from a controlled start — past that, assert
                # the transition (reason + counter advanced), not a count.
                assert_journal_re() {
                  local pattern="$1" f="''${2:-qs.log}" i
                  for i in $(seq 1 40); do
                    grep -qE -- "$pattern" "$f" && return 0
                    sleep 0.25
                  done
                  echo "FAIL: journal pattern '$pattern' not found in $f" >&2
                  tail -20 "$f" >&2
                  exit 1
                }
                assert_no_journal() {
                  local pattern="$1" f="''${2:-qs.log}"
                  if grep -qF -- "$pattern" "$f"; then
                    echo "FAIL: unexpected journal line '$pattern' in $f" >&2
                    exit 1
                  fi
                }

                assert_state false               # clean ok probes: stays hidden
                assert_no_journal "probe failed"  # nothing failed yet
                echo net > control               # failure 1 of 2
                assert_state false               # debounce holds
                assert_journal "probe failed reason=net failures=1/2"
                assert_state true net            # failure 2 of 2: shows
                assert_journal "banner state=shown reason=net failures=2/2"
                # Heartbeat = the state file is REWRITTEN on every probe.
                # updatedAt itself has second granularity (fine for the
                # ~2-interval staleness contract) but two probes 600 ms
                # apart can land in the same second, and a strict field
                # compare then flakes (seen on CI) — the file mtime at ns
                # resolution proves the rewrite without that collision.
                hb1=$(date -r "$state" +%s%N)
                echo link > control              # reason switches
                assert_state true link
                assert_journal "probe failed reason=link failures=3/2"
                hb2=$(date -r "$state" +%s%N)
                [ "$hb2" -gt "$hb1" ] || { echo "FAIL: state file was not rewritten between probes (heartbeat broken)"; exit 1; }
                : > control                      # probe cannot run (empty output): fail visible as net
                assert_state true net
                # failures=4/2 exactly is NOT guaranteed here: while the
                # shell was asserting the link phase, extra link probes
                # kept the counter climbing — the first net line after the
                # switch can read 4/2, 8/2, or higher. Assert the
                # transition (reason back to net, counter past 3).
                assert_journal_re "probe failed reason=net failures=([4-9]|[1-9][0-9]+)/2"
                echo ok > control                # recovery: hides + re-arms
                assert_state false
                assert_journal_re "probe ok recovered_after=([4-9]|[1-9][0-9]+)"
                assert_journal "banner state=hidden reason=net failures=0/2"
                echo net > control               # failure 1 of 2 again
                assert_state false               # debounce holds again
                assert_state true net            # fresh outage shows again

                # Demo mode: a second instance must force-show with probes
                # skipped (previous instance fully reaped first so no stale
                # state write can race the fresh state file).
                kill "$qs_pid" 2>/dev/null || true
                wait "$qs_pid" 2>/dev/null || true
                rm -f "$state"
                OFFLINE_BANNER_DEMO=1 quickshell -p "$qmlDir" >qs-demo.log 2>&1 &
                qs_pid=$!
                assert_state true
                [ "$(jq -r '.demo | tostring' "$state")" = "true" ] || { echo "FAIL: demo flag missing in state: $(cat "$state")"; exit 1; }
                assert_journal "banner state=shown reason=" qs-demo.log

                kill "$qs_pid" "$sway_pid" 2>/dev/null || true
                echo "probe-transitions: all assertions passed" > "$out"
              '';
          # Render smoke: the FIRST pixel-level proof that the banner
          # actually renders. Same headless-sway harness as
          # probe-transitions, but drives the real probe path (control
          # file, not demo mode) and grim-captures HEADLESS-1 at each
          # phase: hidden -> shown -> recovered. The strip is #f2f9e2af
          # at 95% alpha; composited over any background it lands in the
          # accepted R/G/B ranges below (black bg ~236,214,166, white bg
          # ~249,227,179) — asserted at a strip pixel, asserted ABSENT
          # below the strip and after recovery. This is software
          # rendering (QT_QUICK_BACKEND=software, pixman), not a real
          # monitor; hardware-output proof still rides a live session.
          render-smoke =
            let
              qmlDir = builtins.elemAt enabled.config.systemd.user.services.offline-banner.restartTriggers 0;
            in
            pkgs.runCommand "offline-banner-render-smoke"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.jq
                  pkgs.quickshell
                  pkgs.sway
                  pkgs.grim
                  pkgs.imagemagick
                  pkgs.coreutils
                  pkgs.gnugrep
                ];
                inherit qmlDir;
              }
              ''
                export XDG_RUNTIME_DIR="$PWD/runtime"
                export HOME="$PWD/home"
                export XDG_CACHE_HOME="$HOME/cache"
                mkdir -p "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR"
                export QT_QUICK_BACKEND=software
                export QT_QPA_PLATFORM=wayland
                export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

                echo "output HEADLESS-1 mode 1280x800 position 0,0" > sway-config
                WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman \
                  sway --unsupported-gpu -c sway-config >sway.log 2>&1 &
                sway_pid=$!
                sock=""
                for i in $(seq 1 100); do
                  sock=$(ls "$XDG_RUNTIME_DIR" 2>/dev/null | grep -E '^wayland-[0-9]+$' | head -1 || true)
                  [ -n "$sock" ] && break
                  sleep 0.1
                done
                [ -n "$sock" ] || { echo "FAIL: headless sway did not start"; cat sway.log; exit 1; }
                export WAYLAND_DISPLAY="$sock"
                sleep 0.5

                mkdir -p "$XDG_RUNTIME_DIR/offline-banner"
                echo ok > control
                export OFFLINE_BANNER_INTERVAL=600
                export OFFLINE_BANNER_FAILURES=2
                export OFFLINE_BANNER_PROBE_CMD="cat $PWD/control"
                quickshell -p "$qmlDir" >qs.log 2>&1 &
                qs_pid=$!

                state="$XDG_RUNTIME_DIR/offline-banner/state"
                wait_active() {
                  local want="$1" i got
                  for i in $(seq 1 40); do
                    got=$(jq -r '.active | tostring' "$state" 2>/dev/null || true)
                    [ "$got" = "$want" ] && return 0
                    sleep 0.25
                  done
                  echo "FAIL: state never became active=$want" >&2
                  echo "--- qs.log ---" >&2; tail -20 qs.log >&2
                  exit 1
                }
                # Strip pixel color range (see comment above); %[pixel:p{}]
                # prints srgb(r,g,b) — alpha is gone in the composited frame.
                pixel_is_yellow() {
                  magick "$1" -format "%[pixel:p{$2,$3}]" info: | awk -F'[(,)]' \
                    '{ r = $2 + 0; g = $3 + 0; b = $4 + 0
                       exit !(r >= 225 && r <= 255 && g >= 200 && g <= 240 && b >= 150 && b <= 195 && r - b >= 55) }'
                }
                assert_yellow() {
                  pixel_is_yellow "$@" \
                    || { echo "FAIL: expected banner yellow at ($2,$3) in $1, got $(magick "$1" -format "%[pixel:p{$2,$3}]" info:)"; exit 1; }
                }
                assert_not_yellow() {
                  if pixel_is_yellow "$@"; then
                    echo "FAIL: unexpected banner yellow at ($2,$3) in $1"
                    exit 1
                  fi
                }

                wait_active false
                sleep 1                       # settle frames before capture
                grim -o HEADLESS-1 hidden.png
                assert_not_yellow hidden.png 20 10

                echo net > control            # 2 consecutive failures -> show
                wait_active true
                sleep 1.2                     # 450 ms push-down + margin
                grim -o HEADLESS-1 shown.png
                assert_yellow shown.png 20 10
                assert_not_yellow shown.png 640 700   # strip is localized, not a wash

                echo ok > control             # recovery -> slide back up
                wait_active false
                sleep 1.2
                grim -o HEADLESS-1 recovered.png
                assert_not_yellow recovered.png 20 10

                kill "$qs_pid" "$sway_pid" 2>/dev/null || true
                echo "render-smoke: banner hidden -> shown -> recovered, pixel-verified" > "$out"
              '';
          # Shell-content gate: the BUILT shell.qml must actually contain
          # the namespace interpolation and the env-var probe markers —
          # the unit-text contract alone cannot see inside the QML (the
          # cutover session hit exactly this gap). Build-time greps, no
          # IFD: the store QML arrives as a plain build input via
          # restartTriggers.
          shell-content =
            let
              qmlDrv = builtins.elemAt enabled.config.systemd.user.services.offline-banner.restartTriggers 0;
              ns = enabled.config.services.offline-banner.layerNamespace;
            in
            pkgs.runCommand "offline-banner-shell-content"
              {
                nativeBuildInputs = [ pkgs.gnugrep ];
                inherit qmlDrv ns;
              }
              ''
                grep -q "WlrLayershell.namespace: \"$ns\"" "$qmlDrv/shell.qml" \
                  || { echo "FAIL: built QML lost the layerNamespace interpolation"; exit 1; }
                for marker in OFFLINE_BANNER_PROBE_HOST OFFLINE_BANNER_SYSROOT OFFLINE_BANNER_PROBE_CMD; do
                  grep -q "$marker" "$qmlDrv/shell.qml" \
                    || { echo "FAIL: built QML lost $marker"; exit 1; }
                done
                touch "$out"
              '';
          # Docs drift gate: every option the module DECLARES (derived from
          # the eval, so a new/renamed option mechanically fails the gate)
          # must appear in README.md and FEATURES.md, and the README must
          # keep the env-contract mention and the consumer pointers. Docs
          # stay true mechanically, not by discipline.
          docs-drift =
            let
              readme = builtins.readFile ./README.md;
              features = builtins.readFile ./FEATURES.md;
              declaredOptions = builtins.attrNames enabled.options.services.offline-banner;
              optionMissingInDoc = doc: nixpkgs.lib.any (o: !(nixpkgs.lib.hasInfix o doc)) declaredOptions;
            in
            pkgs.runCommand "offline-banner-docs-drift"
              {
                optionsInReadme = toString (!(optionMissingInDoc readme));
                optionsInFeatures = toString (!(optionMissingInDoc features));
                envContractInReadme = toString (
                  nixpkgs.lib.hasInfix "OFFLINE_BANNER_{INTERVAL,PROBE_HOST,PROBE_TIMEOUT,FAILURES}" readme
                );
                quickstartInReadme = toString (
                  nixpkgs.lib.hasInfix "github:LarsArtmann/offline-banner" readme
                  && nixpkgs.lib.hasInfix "nixosModules.default" readme
                );
                declaredList = nixpkgs.lib.concatStringsSep "," declaredOptions;
              }
              ''
                echo "declared options: $declaredList"
                [ "$optionsInReadme" = "1" ] || { echo "FAIL: README is missing a declared option (docs drifted)"; exit 1; }
                [ "$optionsInFeatures" = "1" ] || { echo "FAIL: FEATURES is missing a declared option (docs drifted)"; exit 1; }
                [ "$envContractInReadme" = "1" ] || { echo "FAIL: README no longer documents the OFFLINE_BANNER_* env contract"; exit 1; }
                [ "$quickstartInReadme" = "1" ] || { echo "FAIL: README quickstart lost the flake input / module import pointers"; exit 1; }
                touch "$out"
              '';
        }
      );

      nixosModules = {
        offline-banner = offlineBannerModule;
        default = self.nixosModules.offline-banner;
      };
    };
}
