{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    opencode
    antigravity
    codex
    omp
    hermes
    herdr
  ];
}
