{ pkgs, ... }:

{
  programs = {
    git.enable = true;
    zsh.enable = true;
  };

  environment.systemPackages = with pkgs; [
    wget
    helix
    fzf
    ripgrep
    nixd
  ];
}
