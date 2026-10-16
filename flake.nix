{
  description = "offline-banner: yellow top-strip banner for NixOS desktops while offline (Quickshell layer-shell)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
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
      forAllSystems =
        function: nixpkgs.lib.genAttrs systems (system: function nixpkgs.legacyPackages.${system});
      treefmtEval = forAllSystems (
        pkgs:
        treefmt-nix.lib.evalModule pkgs (_: {
          programs = {
            nixfmt.enable = true;
            statix.enable = true;
          };
          projectRootFile = "flake.nix";
        })
      );
      getPlatform = p: p.stdenv.hostPlatform.system;

      evalModule =
        system: extraModules:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ self.nixosModules.offline-banner ] ++ extraModules;
        };
    in
    {
      formatter = forAllSystems (pkgs: treefmtEval.${getPlatform pkgs}.config.build.wrapper);

      checks = forAllSystems (
        pkgs:
        let
          sys = getPlatform pkgs;
          enabled = evalModule sys [ { services.offline-banner.enable = true; } ];
          disabled = evalModule sys { };
          bad = evalModule sys {
            services.offline-banner = {
              enable = true;
              checkIntervalSeconds = 2;
              probeTimeoutSeconds = 5;
            };
          };
          unit = enabled.config.systemd.user.units."offline-banner.service";
        in
        {
          formatting = treefmtEval.${sys}.config.build.check self;
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
                badConfigAsserts = toString (nixpkgs.lib.length bad.config.assertions);
                toplevelRef = toString enabled.config.system.build.toplevel;
              }
              ''
                [ "$unitPresent" = "1" ] || { echo "FAIL: unit missing when enabled"; exit 1; }
                [ "$unitAbsent" = "1" ] || { echo "FAIL: unit present when disabled"; exit 1; }
                [ "$quickshellInExecStart" = "1" ] || { echo "FAIL: ExecStart does not use quickshell"; exit 1; }
                [ "$envContractInUnit" = "1" ] || { echo "FAIL: OFFLINE_BANNER_* env contract missing from the unit"; exit 1; }
                [ "$memoryMaxSet" = "1" ] || { echo "FAIL: MemoryMax missing"; exit 1; }
                [ "$badConfigAsserts" -ge 1 ] || { echo "FAIL: probeTimeout >= checkInterval must assert"; exit 1; }
                echo "$toplevelRef"
                touch "$out"
              '';
        }
      );

      nixosModules = {
        offline-banner = import ./module.nix;
        default = self.nixosModules.offline-banner;
      };
    };
}
