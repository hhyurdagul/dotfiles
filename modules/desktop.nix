{ pkgs, ... }:

{
  security = {
    polkit.enable = true;
    rtkit.enable = true;
    pam.services.greetd.enableGnomeKeyring = true;
  };

  hardware.i2c.enable = true;
  programs = {
    dconf.enable = true;
    steam.enable = true;
    gamemode.enable = true;
    hyprlock.enable = true;
  };

  hardware.steam-hardware.enable = true;

  services = {
    gvfs.enable = true;
    tumbler.enable = true;
    udisks2.enable = true;
    upower.enable = true;
    power-profiles-daemon.enable = true;
    gnome.gnome-keyring.enable = true;

    logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitchDocked = "ignore";
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [
      "hyprland"
      "gtk"
    ];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    font-awesome
  ];
}
