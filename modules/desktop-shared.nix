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
    upower.enable = true;
    power-profiles-daemon.enable = true;
  };

  # PipeWire audio stack for sound & Quickshell VolumeWidget
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Fonts for Quickshell UI & Nerd Font glyphs
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts-color-emoji
    font-awesome
  ];

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

    # Bar helper utilities (JSON parsing, process listing, Python)
    jq
    procps
    python3

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
