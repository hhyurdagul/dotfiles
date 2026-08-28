{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  environment.systemPackages = [
    pkgs.opencode
    inputs.antigravity.packages.${system}.google-antigravity-cli
    inputs.codex.packages.${system}.default
    inputs.omp.packages.${system}.default
    inputs.hermes.packages.${system}.default
    inputs.herdr.packages.${system}.default
  ];
}
