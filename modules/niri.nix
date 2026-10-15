{ lib, pkgs, ... }:

{
  programs.niri.enable = true;

  # Niri's own systemd session starts/stops graphical-session.target. UWSM
  # remains installed solely for the selectable Hyprland fallback.
  services.greetd.settings.default_session.command = lib.mkForce (
    "${lib.getExe pkgs.tuigreet} --time --battery --remember --asterisks "
    + "--sessions /run/current-system/sw/share/wayland-sessions "
    + "--cmd ${pkgs.niri}/bin/niri-session"
  );

  environment.systemPackages = [ pkgs.xwayland-satellite ];
}
