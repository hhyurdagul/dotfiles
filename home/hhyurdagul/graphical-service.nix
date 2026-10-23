# Base for user services that live and die with the graphical session.
# Extend it with lib.recursiveUpdate.
{
  Unit.PartOf = [ "graphical-session.target" ];
  Install.WantedBy = [ "graphical-session.target" ];
}
