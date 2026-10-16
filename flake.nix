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
                [ "$sandboxInUnit" = "1" ] || { echo "FAIL: sandbox hardening missing from the unit"; exit 1; }
                [ "$noNoNewPrivileges" = "1" ] || { echo "FAIL: NoNewPrivileges must stay unset (it strips cap_net_raw from ping)"; exit 1; }
                [ "$restartTriggersStoreQml" = "1" ] || { echo "FAIL: restartTriggers must reference the store QML (rename drift)"; exit 1; }
                [ "$badProbeOverlapAsserts" -ge 1 ] || { echo "FAIL: probeTimeout >= checkInterval must assert"; exit 1; }
                [ "$goodProbeOverlapAsserts" = "0" ] || { echo "FAIL: probe-overlap assertion fires on a valid config"; exit 1; }
                touch "$out"
              '';
          # Unit-syntax gate: systemd-analyze verify on the rendered unit —
          # catches pin-class typos in serviceConfig mechanically. The gate
          # fails on a non-zero verify exit (errors) AND on any output line
          # naming our unit (warnings); other-unit noise cannot exist here
          # because only this unit is in the sandbox.
          unit-verify =
            pkgs.runCommand "offline-banner-unit-verify"
              {
                nativeBuildInputs = [ pkgs.systemd ];
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
                if ! systemd-analyze verify --man=no ./offline-banner.service >verify.log 2>&1; then
                  echo "FAIL: systemd-analyze verify rejected the unit:" >&2
                  cat verify.log >&2
                  exit 1
                fi
                if grep -i "offline-banner" verify.log; then
                  echo "FAIL: systemd-analyze verify warned about the unit:" >&2
                  cat verify.log >&2
                  exit 1
                fi
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
