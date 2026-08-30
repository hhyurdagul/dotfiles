{ inputs, pkgs, ... }:

{
  imports = [ inputs.hyprland.nixosModules.default ];

  programs.hyprland.enable = true;

  # Hyprland binary cache
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    trusted-users = [ "@wheel" ];
  };

  # Hypr ecosystem utilities
  environment.systemPackages = with pkgs; [
    hypridle
    hyprlock
    hyprpaper
  ];
}
