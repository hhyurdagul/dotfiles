{ inputs, pkgs, ... }:

{
  imports = [ inputs.hyprland.nixosModules.default ];

  programs.hyprland.enable = true;

  # Hypr ecosystem utilities
  environment.systemPackages = with pkgs; [
    hypridle
    hyprpaper
  ];
}
