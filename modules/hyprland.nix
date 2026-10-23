{ inputs, ... }:

{
  imports = [ inputs.hyprland.nixosModules.default ];

  # Selectable fallback session. greetd's default command is set in niri.nix.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
}
