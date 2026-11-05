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
      # The runbook's hardened smoke test as versioned code: the module's
      # EXACT serviceConfig sandbox as a transient user unit, with
      # unit-file specifiers substituted literally (%h -> $HOME, %t ->
      # $XDG_RUNTIME_DIR). A bus transient does not expand specifiers, so
      # the substitution is what lets it exercise the %h ledger hole —
      # the runbook recipe structurally could not, and that blind spot
      # shipped the 2026-11-05 226/NAMESPACE crash loop (systemd-analyze
      # verify cannot see namespace failures at all). Mandatory
      # pre-switch gate: `nix run .#smoke --`, then follow the runbook
      # checklist (unit active, probe ok, forced outage shows, RSS).
      smokeRunner =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          enabled = evalModule system [ { services.offline-banner.enable = true; } ];
          serviceConfig = enabled.config.systemd.user.services.offline-banner.serviceConfig;
          # Sandbox directives a transient can carry verbatim (whitelist:
          # Type/ExecStart/Restart/wantedBy are transient-hostile). List
          # values render as one space-joined line each — unit-file list
          # syntax — one `-p KEY=VALUE` per line, one argv element per
          # line in the props file.
          keepDirectives = [
            "ProtectSystem"
            "ProtectHome"
            "PrivateTmp"
            "RuntimeDirectory"
            "RuntimeDirectoryMode"
            "StateDirectory"
            "StateDirectoryMode"
            "ReadWritePaths"
            "MemoryMax"
            "RestrictAddressFamilies"
            "RestrictNamespaces"
            "LockPersonality"
            "RestrictRealtime"
            "RestrictSUIDSGID"
            "ProtectClock"
            "ProtectHostname"
            "ProtectKernelLogs"
            "ProtectKernelModules"
            "ProtectKernelTunables"
            "ProtectControlGroups"
            "ProtectProc"
            "SystemCallArchitectures"
          ];
          renderDirective =
            name: value:
            "-p ${name}=${
              if builtins.isList value then nixpkgs.lib.concatStringsSep " " value else toString value
            }";
          propsLines =
            map (name: renderDirective name serviceConfig.${name}) (
              nixpkgs.lib.filter (name: nixpkgs.lib.elem name keepDirectives) (
                nixpkgs.lib.attrNames serviceConfig
              )
            )
            ++ nixpkgs.lib.mapAttrsToList (name: value: "-p Environment=${name}=${toString value}") (
              serviceConfig.Environment or { }
            );
        in
        pkgs.runCommand "offline-banner-smoke"
          {
            propsText = nixpkgs.lib.concatStringsSep "\n" propsLines + "\n";
            passAsFile = [ "propsText" ];
            qmlDir = builtins.elemAt enabled.config.systemd.user.services.offline-banner.restartTriggers 0;
          }
          ''
            mkdir -p "$out/bin"
            cat > "$out/bin/offline-banner-smoke" <<'EOF'
            #!/usr/bin/env bash
            # Hardened smoke test: transient user unit under the rendered
            # offline-banner sandbox, specifiers substituted (%h -> $HOME,
            # %t -> $XDG_RUNTIME_DIR) so the %h ledger hole IS exercised.
            # Checklist (AGENTS.md runbook): unit active, probe ok, forced
            # outage shows + writes the ledger, demo shows, RSS << MemoryMax,
            # fontconfig cache warnings gone. Stop with:
            #   systemctl --user stop offline-banner-smoke
            set -euo pipefail
            props_file="@propsFile@"
            qml_dir="@qmlDir@"
            name="offline-banner-smoke"
            runtime="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
            systemctl --user stop "$name.service" 2>/dev/null || true
            systemctl --user reset-failed "$name.service" 2>/dev/null || true
            args=()
            while IFS= read -r line; do
              [ -n "$line" ] || continue
              line="''${line//%h/$HOME}"
              line="''${line//%t/$runtime}"
              args+=("$line")
            done < "$props_file"
            [ -z "''${OFFLINE_BANNER_SMOKE_PROBE_HOST:-}" ] ||
              args+=(-p "Environment=OFFLINE_BANNER_PROBE_HOST=$OFFLINE_BANNER_SMOKE_PROBE_HOST")
            [ -z "''${OFFLINE_BANNER_SMOKE_DEMO:-}" ] ||
              args+=(-p "Environment=OFFLINE_BANNER_DEMO=1")
            echo "offline-banner-smoke: transient '$name' under the rendered sandbox (specifiers substituted: %h -> $HOME, %t -> $runtime)"
            exec systemd-run --user --unit="$name" ''${args[@]} -- quickshell -p "$qml_dir"
            EOF
            sed -e "s|@propsFile@|$propsTextPath|" -e "s|@qmlDir@|$qmlDir|" -i "$out/bin/offline-banner-smoke"
            chmod +x "$out/bin/offline-banner-smoke"
          '';

      # The check class that would have caught the 2026-11-05 226/NAMESPACE
      # incident: a full boot of a normal user with a CLEAN home (no
      # ~/.local/state/offline-banner, no leaked fixture), autologin into
      # the user manager, then the unit started under the REAL sandbox.
      # Asserts: the StateDirectory leaf actually materialized under the
      # clean home, the unit's last death was NOT a namespace/exec setup
      # failure (ExecMainStatus 226/203), and the journal carries no
      # "Failed at step" line for the unit. Deliberately NOT in `checks`
      # pending the owner decision (D1: a tcg VM check makes every CI run
      # minutes slower) — run locally via `nix build .#vm-smoke`, promote
      # into checks.x86_64-linux when decided. A compositor is out of
      # scope: quickshell may exit/restart without a Wayland display — the
      # class-kill asserts only care that exec left the namespace-setup
      # stage behind.
      vmSmoke =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        nixpkgs.lib.nixos.runTest {
          name = "offline-banner-vm-smoke";
          hostPkgs = pkgs;
          nodes.machine =
            { lib, ... }:
            {
              imports = [ offlineBannerModule ];
              services.offline-banner = {
                enable = true;
                # TEST-NET-1: probes fail deterministically in the VM
                # (no network); probe behavior is probe-transitions'
                # scope — this test owns the sandbox/boot path only.
                probeHost = "192.0.2.1";
              };
              users.users.smoke = {
                isNormalUser = true;
                password = "smoke";
              };
              # Autologin boots the user manager (user@uid.service) —
              # the real user-unit environment, no lingering hacks.
              services.getty.autologinUser = "smoke";
            };
          testScript = ''
            uid = machine.succeed("id -u smoke").strip()
            machine.wait_for_unit("multi-user.target")
            machine.wait_for_unit("getty.target")
            machine.wait_for_unit(f"user@{uid}.service")

            # Manual-start path (no graphical session in this VM — same
            # as the origin host's first start): graphical-session.target
            # itself refuses manual start (dependency-only), so the unit
            # is pulled in directly.
            machine.succeed(
                f"su smoke -c 'XDG_RUNTIME_DIR=/run/user/{uid} "
                "systemctl --user start offline-banner.service'"
            )
            machine.wait_until_succeeds(
                f"su smoke -c 'XDG_RUNTIME_DIR=/run/user/{uid} "
                "systemctl --user show offline-banner -p ActiveState'"
                " | grep -q 'ActiveState='",
                timeout=120,
            )

            # The provisioning assert (THE incident): the StateDirectory
            # leaf must materialize under the clean home BEFORE anything
            # binds it. ReadWritePaths binds but never creates — a
            # missing dir dies at NAMESPACE setup, status 226, in a
            # restart loop (2026-11-05 evo-x2).
            machine.succeed("test -d /home/smoke/.local/state/offline-banner")
            machine.succeed(
                "test \"$(stat -c %U /home/smoke/.local/state/offline-banner)\" = smoke"
            )

            # Wait for at least one start attempt to reach a verdict.
            machine.wait_until_succeeds(
                f"su smoke -c 'XDG_RUNTIME_DIR=/run/user/{uid} "
                "systemctl --user show offline-banner -p ExecMainStatus'"
                " | grep -q 'ExecMainStatus='",
                timeout=180,
            )
            state = machine.succeed(
                f"su smoke -c 'XDG_RUNTIME_DIR=/run/user/{uid} "
                "systemctl --user show offline-banner -p ExecMainStatus'"
            ).strip()
            # 226 = namespace setup failed (the incident class); 203 =
            # exec step failed (binary/path drift). Anything else means
            # quickshell actually exec'd through the full sandbox.
            assert "ExecMainStatus=226" not in state, f"unit died in namespace setup: {state}"
            assert "ExecMainStatus=203" not in state, f"unit failed at exec: {state}"

            # Journal class-kill: no "Failed at step" line may exist for
            # the unit, and the exec must have left a trace.
            machine.fail(
                "journalctl _SYSTEMD_USER_UNIT=offline-banner.service "
                "--grep='Failed at step' | grep -q ."
            )
            machine.wait_until_succeeds(
                "journalctl _SYSTEMD_USER_UNIT=offline-banner.service "
                "--grep='Started|Main process|Quickshell|quickshell|Qt' | grep -q .",
                timeout=120,
            )
          '';
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
          # Negative fixture, opt-out side (soundTheme none + history off):
          # the unit must go fully inert — no sound env, no pw-play in
          # PATH, no ledger env, no StateDirectory, no %h write hole — and
          # fire no assertion.
          inert = evalModule system [
            {
              services.offline-banner = {
                enable = true;
                soundTheme = "none";
                enableHistory = false;
              };
            }
          ];
          inertUnit = inert.config.systemd.user.units."offline-banner.service";
          goodInertAsserts = nixpkgs.lib.length (
            failing (standaloneAssertions {
              enable = true;
              soundTheme = "none";
              enableHistory = false;
            })
          );
          # Negative fixture, assertion teeth: a historyPath outside the
          # two provisioned shapes must fire the provisioning assertion at
          # eval time (an absolute-but-unprovisioned parent fires exactly
          # that one; a relative path additionally fails the absolute-path
          # assertion).
          badLedgerAsserts = nixpkgs.lib.length (
            failing (standaloneAssertions {
              enable = true;
              historyPath = "/opt/ledger/history.jsonl";
            })
          );
          badRelativeLedgerAsserts = nixpkgs.lib.length (
            failing (standaloneAssertions {
              enable = true;
              historyPath = "ledger/history.jsonl";
            })
          );
          # The computed provisioning invariant: every ReadWritePaths hole
          # must map to a dir the unit PROVISIONS — %t/<d> via
          # RuntimeDirectory, %h/.local/state/<s> via StateDirectory
          # (user units root StateDirectory at ~/.local/state). The
          # synthetic hole eval (a hand-written hole nothing provisions)
          # must FAIL this same computation, proving the gate has teeth.
          rwProvisioned =
            sc:
            let
              provisioned =
                map (d: "%t/${d}") (sc.RuntimeDirectory or [ ])
                ++ map (s: "%h/.local/state/${s}") (sc.StateDirectory or [ ]);
            in
            nixpkgs.lib.all (hole: nixpkgs.lib.any (p: hole == p) provisioned) (sc.ReadWritePaths or [ ]);
          rwHolesProvisioned = rwProvisioned enabled.config.systemd.user.services.offline-banner.serviceConfig;
          holeEval = evalModule system [
            { services.offline-banner.enable = true; }
            (
              { lib, ... }:
              {
                systemd.user.services.offline-banner.serviceConfig.ReadWritePaths = lib.mkForce [
                  "%t/unprovisioned-hole"
                ];
              }
            )
          ];
          rwInvariantDetectsHole =
            !(rwProvisioned holeEval.config.systemd.user.services.offline-banner.serviceConfig);
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
                    "OFFLINE_BANNER_SOUND_THEME"
                    "OFFLINE_BANNER_SOUND_VOLUME"
                    "OFFLINE_BANNER_SOUNDS"
                    "OFFLINE_BANNER_HISTORY"
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
                    "ReadWritePaths=%h/.local/state/offline-banner"
                  ]
                );
                # The ledger dir must be PROVISIONED, not just bound:
                # ReadWritePaths cannot create its target (2026-11-05 live
                # incident: without StateDirectory the unit died at
                # status=226/NAMESPACE in a restart loop on hosts without
                # ~/.local/state/offline-banner, and the banner was
                # silently absent through every outage). StateDirectory
                # (user units: rooted at ~/.local/state) creates the dir
                # before the mount namespace is applied.
                ledgerDirProvisioned = toString (
                  nixpkgs.lib.all (line: nixpkgs.lib.hasInfix line unit.text) [
                    "StateDirectory=offline-banner"
                    "StateDirectoryMode=0700"
                    "ReadWritePaths=%h/.local/state/offline-banner"
                  ]
                );
                # Deliberate absence: NoNewPrivileges would strip ping's
                # cap_net_raw file capability (see module.nix serviceConfig).
                noNoNewPrivileges = toString (!(nixpkgs.lib.hasInfix "NoNewPrivileges" unit.text));
                # Rename drift: the service must keep restarting on QML
                # AND sound-synthesis changes — exactly two triggers, the
                # store QML and the sounds dir, nothing sneaks in between.
                restartTriggersComplete = toString (
                  let
                    trigs = map toString (enabled.config.systemd.user.services.offline-banner.restartTriggers or [ ]);
                  in
                  nixpkgs.lib.length trigs == 2
                  && nixpkgs.lib.any (t: nixpkgs.lib.hasInfix "shell.qml" t) trigs
                  && nixpkgs.lib.any (t: nixpkgs.lib.hasInfix "offline-banner-sounds" t) trigs
                );
                # pw-play joins the unit PATH only when a sound theme is
                # on; the default config (chime) must carry it.
                pipewireInUnit = toString (nixpkgs.lib.hasInfix "pipewire" unit.text);
                badProbeOverlapAsserts = toString badStandaloneAsserts;
                goodProbeOverlapAsserts = toString goodStandaloneAsserts;
                inertAssertsClean = toString goodInertAsserts;
                inertUnitIsSilent = toString (
                  nixpkgs.lib.all (marker: !(nixpkgs.lib.hasInfix marker inertUnit.text)) [
                    "OFFLINE_BANNER_SOUND_THEME"
                    "OFFLINE_BANNER_SOUND_VOLUME"
                    "OFFLINE_BANNER_SOUNDS"
                    "OFFLINE_BANNER_HISTORY"
                    "pipewire"
                    "StateDirectory"
                  ]
                );
                inertUnitHasNoHomeHole = toString (!(nixpkgs.lib.hasInfix "ReadWritePaths=%h/" inertUnit.text));
                badLedgerShapeAsserts = toString badLedgerAsserts;
                badRelativeLedgerAsserts = toString badRelativeLedgerAsserts;
                rwHolesAllProvisioned = toString rwHolesProvisioned;
                rwHoleGateHasTeeth = toString rwInvariantDetectsHole;
              }
              ''
                [ "$unitPresent" = "1" ] || { echo "FAIL: unit missing when enabled"; exit 1; }
                [ "$unitAbsent" = "1" ] || { echo "FAIL: unit present when disabled"; exit 1; }
                [ "$quickshellInExecStart" = "1" ] || { echo "FAIL: ExecStart does not use quickshell"; exit 1; }
                [ "$envContractInUnit" = "1" ] || { echo "FAIL: OFFLINE_BANNER_* env contract missing from the unit"; exit 1; }
                [ "$memoryMaxSet" = "1" ] || { echo "FAIL: MemoryMax missing"; exit 1; }
                [ "$cacheDirSet" = "1" ] || { echo "FAIL: XDG_CACHE_HOME must point at the runtime dir (fontconfig cache under strict sandbox)"; exit 1; }
                [ "$sandboxInUnit" = "1" ] || { echo "FAIL: sandbox hardening missing from the unit"; exit 1; }
                [ "$ledgerDirProvisioned" = "1" ] || { echo "FAIL: StateDirectory must provision the ledger dir (ReadWritePaths binds but never creates — 2026-11-05 226/NAMESPACE outage)"; exit 1; }
                [ "$noNoNewPrivileges" = "1" ] || { echo "FAIL: NoNewPrivileges must stay unset (it strips cap_net_raw from ping)"; exit 1; }
                [ "$restartTriggersComplete" = "1" ] || { echo "FAIL: restartTriggers must be exactly shell.qml + the sounds store dir (rename drift)"; exit 1; }
                [ "$pipewireInUnit" = "1" ] || { echo "FAIL: pw-play (pipewire) missing from the unit PATH with a sound theme on"; exit 1; }
                [ "$badProbeOverlapAsserts" -ge 1 ] || { echo "FAIL: probeTimeout >= checkInterval must assert"; exit 1; }
                [ "$goodProbeOverlapAsserts" = "0" ] || { echo "FAIL: probe-overlap assertion fires on a valid config"; exit 1; }
                [ "$rwHolesAllProvisioned" = "1" ] || { echo "FAIL: a ReadWritePaths hole lacks a provisioned dir (ReadWritePaths binds but never creates — 226/NAMESPACE class)"; exit 1; }
                [ "$rwHoleGateHasTeeth" = "1" ] || { echo "FAIL: the provisioning invariant did NOT flag the synthetic unprovisioned hole (gate has no teeth)"; exit 1; }
                [ "$inertAssertsClean" = "0" ] || { echo "FAIL: the opt-out config (soundTheme none + history off) must not fire any assertion"; exit 1; }
                [ "$inertUnitIsSilent" = "1" ] || { echo "FAIL: soundTheme=none + enableHistory=false must leave the unit silent and ledger-less"; exit 1; }
                [ "$inertUnitHasNoHomeHole" = "1" ] || { echo "FAIL: history off must remove the %h write hole"; exit 1; }
                [ "$badLedgerShapeAsserts" -ge 1 ] || { echo "FAIL: an unprovisioned historyPath parent (/opt/...) must fail the eval assertion"; exit 1; }
                [ "$badRelativeLedgerAsserts" -ge 1 ] || { echo "FAIL: a relative historyPath must fail the absolute-path assertion"; exit 1; }
                touch "$out"
              '';
          # The smoke script must stay runnable: bash syntax plus the
          # structural markers — transient exec, BOTH specifier
          # substitutions, props-file consumption (a refactor losing the
          # %h substitution would silently re-open the runbook blind spot
          # the app exists to close).
          # Shell gates: the reference consumer and the host scripts are
          # copy-paste surfaces users run as-is — they stay shellcheck
          # (-S warning) clean and shfmt canonical.
          shell-scripts =
            pkgs.runCommand "offline-banner-shell-scripts"
              {
                nativeBuildInputs = [
                  pkgs.shellcheck
                  pkgs.shfmt
                ];
                contrib = ./contrib/offline-banner-waybar;
                playSounds = ./scripts/play-sounds.sh;
                captureDemo = ./scripts/capture-demo.sh;
              }
              ''
                for f in "$contrib" "$playSounds" "$captureDemo"; do
                  echo "gating $f"
                  shellcheck -S warning "$f" || { echo "FAIL: shellcheck on $f"; exit 1; }
                  shfmt -d "$f" || { echo "FAIL: shfmt on $f (run: shfmt -w $f)"; exit 1; }
                done
                touch "$out"
              '';
          smoke-script =
            pkgs.runCommand "offline-banner-smoke-script"
              {
                script = "${smokeRunner system}/bin/offline-banner-smoke";
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.coreutils
                  pkgs.gnugrep
                ];
              }
              ''
                bash -n "$script"
                grep -q "exec systemd-run --user" "$script" || { echo "FAIL: smoke script lost the systemd-run exec"; exit 1; }
                grep -q 'line="''${line//%h/$HOME}"' "$script" || { echo "FAIL: smoke script lost the %h substitution (ledger hole untested)"; exit 1; }
                grep -q 'line="''${line//%t/$runtime}"' "$script" || { echo "FAIL: smoke script lost the %t substitution"; exit 1; }
                grep -q 'done < "$props_file"' "$script" || { echo "FAIL: smoke script no longer consumes the derived props file"; exit 1; }
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
                # Sound + ledger seams: the sound override records every
                # cue ($1 = event, $2 = wav) into sounds.log; the outage
                # ledger lands in history.jsonl. Neither env is part of a
                # bare run — unset, both features stay inert.
                export OFFLINE_BANNER_SOUND_THEME=chime
                export OFFLINE_BANNER_HISTORY="$PWD/history.jsonl"
                export OFFLINE_BANNER_SOUND_CMD="echo \"\$1 \$2\" >> $PWD/sounds.log"
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
                # failures=3/2 exactly is NOT guaranteed: a third net
                # probe can slip in before the shell writes `link` (seen
                # on CI) — the first link line is reason=link with the
                # counter past the two net failures that showed it.
                assert_journal_re "probe failed reason=link failures=([3-9]|[1-9][0-9]+)/2"
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

                # Ledger: the outage above must be closed as ONE entry —
                # from the first net failure to this recovery, both reasons
                # seen, at least the four logged failures. state.since
                # clears with it.
                assert_journal_re "outage ended from=[0-9]+ to=[0-9]+ duration=[0-9]+s reasons=net,link"
                [ -s history.jsonl ] || { echo "FAIL: outage history file missing/empty"; exit 1; }
                entries=$(wc -l < history.jsonl)
                [ "$entries" = "1" ] || { echo "FAIL: expected exactly 1 history entry, got $entries"; exit 1; }
                jq -e '(.to > .from) and (.durationSec >= 1) and (.reasons == ["net","link"]) and (.probeFailures >= 4)' history.jsonl > /dev/null \
                  || { echo "FAIL: history entry wrong: $(cat history.jsonl)"; exit 1; }
                [ "$(jq -r '.since | if . == null then "null" else "set" end' "$state")" = "null" ] \
                  || { echo "FAIL: state.since must clear on recovery: $(cat "$state")"; exit 1; }

                # Sounds fired exactly at the transitions: one cue at show
                # (net — reason switches mid-outage do NOT re-sound, hence
                # the negative assert below) and one at recovery.
                assert_journal "offline-net" sounds.log
                assert_journal "recover" sounds.log
                assert_no_journal "offline-link" sounds.log
                echo net > control               # failure 1 of 2 again
                assert_state false               # debounce holds again
                assert_state true net            # fresh outage shows again

                # A fresh outage re-sounds and re-arms `since`; it stays
                # OPEN here (no recovery probe), so it must NOT close a
                # second ledger entry.
                n=0
                for i in $(seq 1 40); do
                  # NOTE: no shell parameter expansion here — literal
                  # dollar-brace sequences inside this Nix indented
                  # string get silently corrupted by the Nix lexer
                  # (AGENTS.md hard rule); POSIX-safe guards only
                  # (grep -c prints "0" even on no match).
                  n=$(grep -c "offline-net" sounds.log 2>/dev/null || true)
                  [ -z "$n" ] && n=0
                  [ "$n" -ge 2 ] && break
                  sleep 0.25
                done
                [ "$n" -ge 2 ] || { echo "FAIL: fresh outage must re-sound (offline-net x2), got $n: $(cat sounds.log 2>/dev/null)"; exit 1; }
                [ "$(jq -r '.since | if . == null then "null" else "set" end' "$state")" = "set" ] \
                  || { echo "FAIL: state.since must be set while shown: $(cat "$state")"; exit 1; }
                entries=$(wc -l < history.jsonl)
                [ "$entries" = "1" ] || { echo "FAIL: an open outage must not close an entry (expected 1, got $entries)"; exit 1; }

                # Link-cue POSITIVE assert: trip a clean-start outage on
                # reason=link — its own instance and a fresh sound log, so
                # the one-cue-per-outage doctrine is asserted for the link
                # reason too (until now only negatively: the net-tripped
                # outage above must NOT have played it). Exact counts are
                # deterministic here: a fresh instance's first probe is
                # failures=1/2, and no same-reason failure ever re-sounds.
                kill "$qs_pid" 2>/dev/null || true
                wait "$qs_pid" 2>/dev/null || true
                rm -f "$state"
                export OFFLINE_BANNER_SOUND_CMD="echo \"\$1 \$2\" >> $PWD/sounds-link.log"
                echo link > control
                quickshell -p "$qmlDir" >qs-link.log 2>&1 &
                qs_pid=$!
                assert_journal "probe failed reason=link failures=1/2" qs-link.log
                assert_state true link
                assert_journal "banner state=shown reason=link failures=2/2" qs-link.log
                n=0
                for i in $(seq 1 40); do
                  n=$(grep -c "offline-link" sounds-link.log 2>/dev/null || true)
                  [ -z "$n" ] && n=0
                  [ "$n" -ge 1 ] && break
                  sleep 0.25
                done
                [ "$n" = "1" ] || { echo "FAIL: clean link outage must cue offline-link exactly once, got $n: $(cat sounds-link.log 2>/dev/null)"; exit 1; }
                assert_no_journal "recover" sounds-link.log
                assert_no_journal "offline-net" sounds-link.log
                [ "$(jq -r '.since | if . == null then "null" else "set" end' "$state")" = "set" ] \
                  || { echo "FAIL: link outage must arm since: $(cat "$state")"; exit 1; }
                entries=$(wc -l < history.jsonl)
                [ "$entries" = "1" ] || { echo "FAIL: open link outage must not close a second entry (expected 1, got $entries)"; exit 1; }

                # Demo mode: a second instance must force-show with probes
                # skipped (previous instance fully reaped first so no stale
                # state write can race the fresh state file).
                kill "$qs_pid" 2>/dev/null || true
                wait "$qs_pid" 2>/dev/null || true
                rm -f "$state"
                # Sound seam unset: the demo instance has no store dir
                # either, so it stays silent even though the theme env
                # inherits — demo is a fake outage and must not beep.
                unset OFFLINE_BANNER_SOUND_CMD
                OFFLINE_BANNER_DEMO=1 quickshell -p "$qmlDir" >qs-demo.log 2>&1 &
                qs_pid=$!
                assert_state true
                [ "$(jq -r '.demo | tostring' "$state")" = "true" ] || { echo "FAIL: demo flag missing in state: $(cat "$state")"; exit 1; }
                assert_journal "banner state=shown reason=" qs-demo.log

                # Demo mode is a FAKE outage: no ledger entry, ever.
                entries=$(wc -l < history.jsonl)
                [ "$entries" = "1" ] || { echo "FAIL: demo mode must not write history (expected 1 entry, got $entries)"; exit 1; }

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
                # Transition-style pixel poll (CI-timing doctrine, same as
                # probe-transitions): after a control switch, assert the
                # OBSERVED frame transition with a bounded retry instead of a
                # sleep-then-single-shot — slow runners get more time, not
                # flakes. The captures below stay as settled evidence frames.
                wait_pixel() {
                  local want="$1" x="$2" y="$3" i
                  for i in $(seq 1 40); do
                    grim -o HEADLESS-1 frame.png
                    if [ "$want" = yellow ]; then
                      pixel_is_yellow frame.png "$x" "$y" && return 0
                    else
                      pixel_is_yellow frame.png "$x" "$y" || return 0
                    fi
                    sleep 0.25
                  done
                  echo "FAIL: pixel ($x,$y) never became $want after 10s" >&2
                  echo "--- qs.log ---" >&2; tail -20 qs.log >&2
                  exit 1
                }

                wait_active false
                sleep 1                       # settle frames before capture
                grim -o HEADLESS-1 hidden.png
                assert_not_yellow hidden.png 20 10

                echo net > control            # 2 consecutive failures -> show
                wait_active true
                wait_pixel yellow 20 10       # strip entering the frame
                sleep 1.2                     # let the 450 ms push-down fully settle
                grim -o HEADLESS-1 shown.png
                assert_yellow shown.png 20 10
                assert_not_yellow shown.png 640 700   # strip is localized, not a wash

                echo ok > control             # recovery -> slide back up
                wait_active false
                wait_pixel not-yellow 20 10   # strip leaving the frame
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
              triggers = enabled.config.systemd.user.services.offline-banner.restartTriggers;
              qmlDrv = builtins.elemAt triggers 0;
              soundsDrv = builtins.elemAt triggers 1;
              ns = enabled.config.services.offline-banner.layerNamespace;
            in
            pkgs.runCommand "offline-banner-shell-content"
              {
                nativeBuildInputs = [
                  pkgs.gnugrep
                  pkgs.python3
                ];
                inherit qmlDrv soundsDrv ns;
              }
              ''
                grep -q "WlrLayershell.namespace: \"$ns\"" "$qmlDrv/shell.qml" \
                  || { echo "FAIL: built QML lost the layerNamespace interpolation"; exit 1; }
                for marker in OFFLINE_BANNER_PROBE_HOST OFFLINE_BANNER_SYSROOT OFFLINE_BANNER_PROBE_CMD OFFLINE_BANNER_SOUND_THEME OFFLINE_BANNER_SOUND_CMD OFFLINE_BANNER_HISTORY pw-play; do
                  grep -q "$marker" "$qmlDrv/shell.qml" \
                    || { echo "FAIL: built QML lost $marker"; exit 1; }
                done
                # The sound set is the OTHER build-time artifact: the full
                # 3x4 theme/event matrix must exist and every file must be
                # a valid sub-second 44.1 kHz mono WAV — catches a silently
                # broken synthesis (bad frequencies, empty render).
                for theme in chime droplet retro; do
                  for event in offline-net offline-link recover dismiss; do
                    f="$soundsDrv/$theme-$event.wav"
                    [ -s "$f" ] || { echo "FAIL: missing sound $theme-$event.wav"; exit 1; }
                  done
                done
                for f in "$soundsDrv"/*.wav; do
                  python3 -c 'import sys, wave; w = wave.open(sys.argv[1]); assert 1000 < w.getnframes() <= 44100 and w.getframerate() == 44100 and w.getnchannels() == 1, sys.argv[1]' "$f" \
                    || { echo "FAIL: bad wav (must be >0.02s, <=1s, 44.1kHz mono): $f"; exit 1; }
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

      packages = forAllSystems (
        system:
        let
          enabled = evalModule system [
            { services.offline-banner.enable = true; }
          ];
        in
        {
          smoke = smokeRunner system;
          vm-smoke = vmSmoke system;
          # The synthesized 3x4 sound matrix, for auditioning without a
          # running unit (scripts/play-sounds.sh falls back to it).
          sounds = builtins.elemAt enabled.config.systemd.user.services.offline-banner.restartTriggers 1;
        }
      );

      apps = forAllSystems (system: {
        smoke = {
          type = "app";
          program = "${smokeRunner system}/bin/offline-banner-smoke";
        };
      });

      nixosModules = {
        offline-banner = offlineBannerModule;
        default = self.nixosModules.offline-banner;
      };
    };
}
