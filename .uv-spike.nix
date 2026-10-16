let
  flake = builtins.getFlake (toString /home/lars/projects/offline-banner);
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  lib = flake.inputs.nixpkgs.lib;
  m = import /home/lars/projects/offline-banner/module.nix;
  unitText =
    (lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ m { services.offline-banner.enable = true; } ];
    }).config.systemd.user.units."offline-banner.service".text;
in
pkgs.runCommand "uv-spike4"
  {
    nativeBuildInputs = [ pkgs.systemd ];
    unitText = unitText;
    passAsFile = [ "unitText" ];
  }
  ''
    cp "$unitTextPath" ./u.service
    {
      echo "=== verify (console target) ==="
      SYSTEMD_LOG_TARGET=console systemd-analyze verify --system --man=no "$PWD/u.service" 2>&1
      echo "verify_exit=$?"
      echo "=== verify (plain, no env) ==="
      systemd-analyze verify --man=no ./u.service 2>&1
      echo "verify_exit=$?"
    } > report.txt 2>&1 || true
    cp report.txt "$out"
    exit 0
  ''
