{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [ inputs.hyprland.nixosModules.default ];

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${lib.getExe pkgs.tuigreet} --time --battery --remember --remember-user-session --asterisks --cmd '${lib.getExe config.programs.uwsm.package} start -F -- ${lib.getExe config.programs.hyprland.package}'";
      user = "greeter";
    };
  };
}
