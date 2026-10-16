{
  description = "offline-banner: yellow top-strip banner for NixOS desktops while offline (Quickshell layer-shell)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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
                sandboxInUnit = toString (
                  nixpkgs.lib.all (line: nixpkgs.lib.hasInfix line unit.text) [
                    "ProtectSystem=strict"
                    "RestrictAddressFamilies="
                    "ProtectKernelTunables=true"
                  ]
                );
                # Deliberate absence: NoNewPrivileges would strip ping's
                # cap_net_raw file capability (see module.nix serviceConfig).
                noNoNewPrivileges = toString (!(nixpkgs.lib.hasInfix "NoNewPrivileges" unit.text));
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
                [ "$badProbeOverlapAsserts" -ge 1 ] || { echo "FAIL: probeTimeout >= checkInterval must assert"; exit 1; }
                [ "$goodProbeOverlapAsserts" = "0" ] || { echo "FAIL: probe-overlap assertion fires on a valid config"; exit 1; }
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
