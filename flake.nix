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

      enabledEval = evalModule "x86_64-linux" [ { services.offline-banner.enable = true; } ];
      disabledEval = evalModule "x86_64-linux" { };
      badEval = evalModule "x86_64-linux" {
        services.offline-banner = {
          enable = true;
          checkIntervalSeconds = 2;
          probeTimeoutSeconds = 5;
        };
      };

      enabledUnit = enabledEval.config.systemd.user.units."offline-banner.service";
      flags = {
        unitPresent = toString (enabledEval.config.systemd.user.units ? "offline-banner.service");
        unitAbsent = toString (!(disabledEval.config.systemd.user.units ? "offline-banner.service"));
        quickshellInExecStart = toString (nixpkgs.lib.hasInfix "quickshell" enabledUnit.text);
        namespaceInQml = toString (
          nixpkgs.lib.hasInfix ''namespace: "offline-banner"'' enabledUnit.text
        );
        badConfigAsserts = toString (nixpkgs.lib.length badEval.config.assertions);
      };
    in
    {
      formatter = forAllSystems (pkgs: treefmtEval.${getPlatform pkgs}.config.build.wrapper);

      checks = forAllSystems (pkgs:
        {
          formatting = treefmtEval.${getPlatform pkgs}.config.build.check self;
          module-contract = pkgs.runCommand "offline-banner-module-contract"
            {
              inherit (flags)
                unitPresent
                unitAbsent
                quickshellInExecStart
                namespaceInQml
                badConfigAsserts
                ;
              toplevelRef = toString enabledEval.config.system.build.toplevel;
            }
            ''
              [ "$unitPresent" = "1" ] || { echo "FAIL: unit missing when enabled"; exit 1; }
              [ "$unitAbsent" = "1" ] || { echo "FAIL: unit present when disabled"; exit 1; }
              [ "$quickshellInExecStart" = "1" ] || { echo "FAIL: ExecStart does not use quickshell"; exit 1; }
              [ "$namespaceInQml" = "1" ] || { echo "FAIL: layer namespace not wired into the QML"; exit 1; }
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
