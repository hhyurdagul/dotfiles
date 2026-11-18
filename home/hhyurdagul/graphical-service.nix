# Base for user services that live and die with the graphical session.
# Extend it with lib.recursiveUpdate. The compositor reaches
# graphical-session.target only after exporting WAYLAND_DISPLAY and
# NIRI_SOCKET, so ordering after it is what gives services that environment.
# recursiveUpdate replaces lists: a service that sets its own Unit.After must
# repeat "graphical-session.target".
{
  Unit = {
    PartOf = [ "graphical-session.target" ];
    After = [ "graphical-session.target" ];
  };
  Install.WantedBy = [ "graphical-session.target" ];
}
