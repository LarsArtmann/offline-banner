let pkgs = (builtins.getFlake (toString /home/lars/projects/offline-banner)).inputs.nixpkgs.legacyPackages.x86_64-linux; in pkgs.runCommand "run-probe" { } ''
  ls / > "$out" 2>&1 || true
  echo "--- /run:" >> "$out"
  ls /run >> "$out" 2>&1 || echo "NO /run" >> "$out"
''
