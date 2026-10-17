export const heroCode = `# flake.nix
inputs.offline-banner.url = "github:LarsArtmann/offline-banner";

# your NixOS configuration
services.offline-banner.enable = true;`;
