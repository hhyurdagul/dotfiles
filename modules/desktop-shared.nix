{ pkgs, ... }:

{
  # Core desktop privileges & hardware access
  security.polkit.enable = true;
  hardware.i2c.enable = true;

  # Desktop file managers & storage daemon integration
  services = {
    gvfs.enable = true;
    tumbler.enable = true;
    udisks2.enable = true;
  };

  # Common Wayland tools and desktop applications shared across compositors
  environment.systemPackages = with pkgs; [
    # Session & Shell essentials
    kitty
    quickshell
    fuzzel
    wlogout
    nautilus
    swaynotificationcenter
    libnotify
    networkmanagerapplet

    # Media & Audio
    pavucontrol
    playerctl

    # Display & Brightness
    brightnessctl
    ddcutil

    # Clipboard & Screenshots
    wl-clipboard
    cliphist
    grim
    slurp
    swappy
  ];
}
