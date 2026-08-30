{ pkgs, ... }:

{
  programs.niri.enable = true;

  # XWayland satellite for running X11 apps under Niri
  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
