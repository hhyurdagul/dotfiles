{ inputs, pkgs, ... }:

{
  imports = [ inputs.hyprland.nixosModules.default ];

  programs.hyprland.enable = true;

  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    # Root is trusted by default; wheel users are administrators on this host.
    trusted-users = [ "@wheel" ];
  };

  # Loads i2c-dev and grants local desktop sessions access to /dev/i2c-*.
  hardware.i2c.enable = true;

  # Desktop integration required by graphical file managers and applications.
  security.polkit.enable = true;
  services = {
    gvfs.enable = true;
    tumbler.enable = true;
    udisks2.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # Session essentials
    fuzzel
    hypridle
    hyprlock
    hyprpaper
    kitty
    nautilus
    swaynotificationcenter
    quickshell
    wlogout

    # Wayland utilities
    brightnessctl
    ddcutil
    cliphist
    grim
    libnotify
    networkmanagerapplet
    pavucontrol
    playerctl
    slurp
    swappy
    wl-clipboard
  ];
}
