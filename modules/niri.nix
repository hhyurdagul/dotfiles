{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.niri.enable = true;

  # Niri's own systemd session starts/stops graphical-session.target. UWSM
  # remains installed solely for the selectable Hyprland fallback.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command =
        "${lib.getExe pkgs.tuigreet} --time --battery --remember --asterisks "
        + "--sessions /run/current-system/sw/share/wayland-sessions "
        + "--cmd ${config.programs.niri.package}/bin/niri-session";
      user = "greeter";
    };
  };

  environment.systemPackages = [ pkgs.xwayland-satellite ];
}
