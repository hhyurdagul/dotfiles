{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  hyprlandPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  makeWallpaper =
    name: color:
    pkgs.runCommand "${name}.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
      magick -size 32x32 "xc:#${color}" "$out"
    '';
  darkWallpaper = makeWallpaper "catppuccin-mocha-wallpaper" "1e1e2e";
  lightWallpaper = makeWallpaper "catppuccin-latte-wallpaper" "eff1f5";

  themeSwitcher = pkgs.writeShellApplication {
    name = "theme-switcher";
    runtimeInputs = with pkgs; [
      coreutils
      darkman
      dconf
      hyprlandPackage
      glib
      procps
    ];
    text = builtins.readFile ../../config/scripts/theme-switcher.sh;
  };

  idleToggle = pkgs.writeShellApplication {
    name = "idle-toggle";
    runtimeInputs = with pkgs; [
      libnotify
      systemd
    ];
    text = builtins.readFile ../../config/scripts/idle-toggle.sh;
  };

  lockScreen = pkgs.writeShellApplication {
    name = "lock-screen";
    runtimeInputs = with pkgs; [
      hyprlock
      procps
      systemd
    ];
    text = builtins.readFile ../../config/scripts/lock.sh;
  };

  nightlightToggle = pkgs.writeShellApplication {
    name = "nightlight-toggle";
    runtimeInputs = with pkgs; [
      libnotify
      systemd
    ];
    text = builtins.readFile ../../config/scripts/nightlight-toggle.sh;
  };

  clipboardWatch = pkgs.writeShellApplication {
    name = "clipboard-watch";
    runtimeInputs = with pkgs; [
      cliphist
      wl-clipboard
    ];
    text = ''
      exec wl-paste --type text --watch cliphist store
    '';
  };

  weatherStatus = pkgs.writeScriptBin "weather-status" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ../../config/quickshell/scripts/weather.py}
  '';

  graphicalService = {
    Unit = {
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
in
{
  home = {
    packages = [
      clipboardWatch
      idleToggle
      lockScreen
      nightlightToggle
      themeSwitcher
      weatherStatus
    ];

    file = {
      ".local/share/light-mode.d/00-theme".source = pkgs.writeShellScript "darkman-light-theme" ''
        exec ${lib.getExe themeSwitcher} light --from-darkman
      '';
      ".local/share/dark-mode.d/00-theme".source = pkgs.writeShellScript "darkman-dark-theme" ''
        exec ${lib.getExe themeSwitcher} dark --from-darkman
      '';
    };

    activation.initializeThemeState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/theme"
      mkdir -p "$state_dir"

      if [[ ! -e "$state_dir/mode" ]]; then
        if [[ -r "$HOME/.config/theme/mode" ]]; then
          tr -d '[:space:]' < "$HOME/.config/theme/mode" > "$state_dir/mode"
        else
          printf '%s\n' dark > "$state_dir/mode"
        fi
      fi

      mode="$(tr -d '[:space:]' < "$state_dir/mode")"
      case "$mode" in
        light)
          cp -- ${../../config/kitty/themes/catppuccin-latte.conf} "$state_dir/kitty.conf"
          ;;
        *)
          printf '%s\n' dark > "$state_dir/mode"
          cp -- ${../../config/kitty/themes/catppuccin-mocha.conf} "$state_dir/kitty.conf"
          ;;
      esac
    '';
  };
  xdg.configFile = {
    "hypr/hyprpaper.conf".text = ''
      wallpaper {
        monitor =
        path = ${darkWallpaper}
        fit_mode = fill
      }
      splash = false
      ipc = true
    '';
    "hypr/wallpapers/dark.png".source = darkWallpaper;
    "hypr/wallpapers/light.png".source = lightWallpaper;
  };

  systemd.user.services = {
    quickshell = lib.recursiveUpdate graphicalService {
      Unit.Description = "Quickshell desktop shell";
      Service = {
        ExecStart = "${lib.getExe pkgs.quickshell} --no-duplicate";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    hypridle = lib.recursiveUpdate graphicalService {
      Unit.Description = "Hyprland idle manager";
      Service = {
        ExecStart = lib.getExe pkgs.hypridle;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    darkman = lib.recursiveUpdate graphicalService {
      Unit.Description = "Automatic light and dark mode";
      Service = {
        ExecStart = "${lib.getExe pkgs.darkman} run";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    theme-initialize = lib.recursiveUpdate graphicalService {
      Unit = {
        Description = "Apply the saved desktop theme";
        After = [ "darkman.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe themeSwitcher} init";
      };
    };

    wlsunset = lib.recursiveUpdate graphicalService {
      Unit.Description = "Automatic night-light temperature";
      Service = {
        ExecStart = "${lib.getExe pkgs.wlsunset} -l 41.0082 -L 28.9784 -t 2500 -T 6500";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    hyprpaper = lib.recursiveUpdate graphicalService {
      Unit.Description = "Hyprland wallpaper daemon";
      Service = {
        ExecStart = "${lib.getExe pkgs.hyprpaper} -c %h/.config/hypr/hyprpaper.conf";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    network-manager-applet = lib.recursiveUpdate graphicalService {
      Unit.Description = "NetworkManager tray applet";
      Service = {
        ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    clipboard-watch = lib.recursiveUpdate graphicalService {
      Unit.Description = "Wayland clipboard history watcher";
      Service = {
        ExecStart = lib.getExe clipboardWatch;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
