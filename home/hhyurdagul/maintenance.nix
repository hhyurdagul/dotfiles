{
  lib,
  pkgs,
  ...
}:

let
  diskHealthNotify = pkgs.writeShellApplication {
    name = "disk-health-notify";
    runtimeInputs = with pkgs; [
      libnotify
      python3
      systemd
    ];
    text = ''
      exec python3 ${../../config/scripts/disk-health-notify.py}
    '';
  };
  graphicalService = import ./graphical-service.nix;
in
{
  home.packages = [ diskHealthNotify ];

  systemd.user.services.disk-health-notify = lib.recursiveUpdate graphicalService {
    Unit = {
      Description = "Show recorded disk-health alerts";
      After = [ "quickshell.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe diskHealthNotify;
      TimeoutStartSec = "1min";
    };
  };

  systemd.user.timers.disk-health-notify = lib.recursiveUpdate graphicalService {
    Unit.Description = "Deliver new disk-health alerts without repeating them";
    Timer = {
      OnActiveSec = "30s";
      OnUnitActiveSec = "5min";
      Unit = "disk-health-notify.service";
    };
  };
}
