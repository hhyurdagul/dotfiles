{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  hyprlandPackage = inputs.hyprland.packages.${system}.hyprland;
  # Handy types into the focused window with wtype and keeps results on the
  # clipboard with wl-copy. It looks both up on PATH, so pin them here instead
  # of relying on whatever PATH the service or launcher inherits.
  # The package skips wrapGAppsHook. Without the GNOME interface schemas, GTK
  # on Wayland leaves gtk-xft-dpi at -1. WebKitGTK turns that into a negative
  # zoom, and the window stays blank apart from the footer.
  # Its automatic device choice puts the model on the RTX 4050, and the GPU
  # picker sits behind experimental settings. Hiding the NVIDIA Vulkan driver
  # leaves the Intel iGPU: about 4x slower than NVIDIA, still ~20x realtime,
  # and the dGPU can stay powered off.
  handy = pkgs.symlinkJoin {
    name = "handy";
    paths = [ inputs.llm-agents.packages.${system}.handy ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/handy --prefix PATH : ${
        lib.makeBinPath [
          pkgs.wl-clipboard
          pkgs.wtype
        ]
      } \
        --prefix XDG_DATA_DIRS : ${pkgs.glib.getSchemaDataDirPath pkgs.gsettings-desktop-schemas} \
        --set VK_LOADER_DRIVERS_DISABLE '*nvidia*'
    '';
    meta.mainProgram = "handy";
  };
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
      hyprlandPackage
      glib
    ];
    # gsettings needs compiled schemas and the dconf GSettings backend. Neither
    # is visible in systemd-user or Hyprland-exec contexts (darkman hooks,
    # theme-initialize, the keybind): without these exports every gsettings
    # call fails with "No schemas installed" and dconf is never updated.
    text = ''
      export GSETTINGS_SCHEMA_DIR="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas"
      export GIO_EXTRA_MODULES="${pkgs.dconf.lib}/lib/gio/modules"
      CURSOR_THEME="${config.home.pointerCursor.name}"
      CURSOR_SIZE="${toString config.home.pointerCursor.size}"
    ''
    + builtins.readFile ../../config/scripts/theme-switcher.sh;
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

  displayPower = pkgs.writeShellApplication {
    name = "display-power";
    runtimeInputs = [
      pkgs.niri
      hyprlandPackage
    ];
    text = builtins.readFile ../../config/scripts/display-power.sh;
  };

  monitorToggle = pkgs.writeShellApplication {
    name = "monitor-toggle";
    runtimeInputs = [
      pkgs.niri
      pkgs.jq
    ];
    text = builtins.readFile ../../config/scripts/monitor-toggle.sh;
  };

  focusOrLaunch = pkgs.writeShellApplication {
    name = "focus-or-launch";
    runtimeInputs = [
      pkgs.niri
      pkgs.jq
    ];
    text = builtins.readFile ../../config/scripts/focus-or-launch.sh;
  };

  niriDisplayPolicy = pkgs.writeScriptBin "niri-display-policy" ''
    #!${pkgs.python3}/bin/python3
    ${builtins.readFile ../../config/scripts/niri-display-policy.py}
  '';

  sessionExit = pkgs.writeShellApplication {
    name = "session-exit";
    runtimeInputs = [
      lockScreen
      pkgs.niri
      pkgs.uwsm
    ];
    text = builtins.readFile ../../config/scripts/session-exit.sh;
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
      exec wl-paste --type "''${1:-text}" --watch cliphist store
    '';
  };

  clipboardHistory = pkgs.writeShellApplication {
    name = "clipboard-history";
    runtimeInputs = with pkgs; [
      python3
      cliphist
      wl-clipboard
      file
    ];
    text = ''
      exec python3 ${../../config/quickshell/scripts/clipboard-history.py} "$@"
    '';
  };

  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [
      coreutils
      grim
      slurp
      wl-clipboard
      libnotify
      util-linux
    ];
    text = builtins.readFile ../../config/scripts/screenshot.sh;
  };

  quickshellSession = pkgs.writeShellApplication {
    name = "quickshell-session";
    runtimeInputs = [
      clipboardHistory
      hyprlandPackage
      pkgs.niri
      pkgs.quickshell
      pkgs.jq
      pkgs.coreutils
    ];
    text = builtins.readFile ../../config/scripts/quickshell-session.sh;
  };

  desktopControl = pkgs.writeShellApplication {
    name = "desktop-control";
    runtimeInputs = [
      hyprlandPackage
      pkgs.niri
    ]
    ++ (with pkgs; [
      brightnessctl
      coreutils
      ddcutil
      gawk
      jq
      quickshell
      util-linux
      wireplumber
    ]);
    text = builtins.readFile ../../config/scripts/desktop-control.sh;
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
  services.syncthing.enable = true;

  home = {
    packages = [
      clipboardHistory
      clipboardWatch
      desktopControl
      displayPower
      focusOrLaunch
      handy
      idleToggle
      lockScreen
      nightlightToggle
      monitorToggle
      sessionExit
      screenshot
      quickshellSession
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
      if [[ "$mode" != light ]]; then
        printf '%s\n' dark > "$state_dir/mode"
      fi
    '';
  };
  xdg.configFile = {
    "niri/config.kdl".text =
      builtins.replaceStrings
        [
          ''"desktop-control"''
          ''"lock-screen"''
          ''"idle-toggle"''
          ''"nightlight-toggle"''
          ''"theme-switcher"''
          ''"monitor-toggle"''
          ''"focus-or-launch"''
          ''"session-exit"''
          ''"handy"''
          ''"~/.local/state/theme/niri.kdl"''
          ''xcursor-theme "Breeze_Light"''
          "xcursor-size 12"
          ''XCURSOR_THEME "Breeze_Light"''
          ''XCURSOR_SIZE "12"''
        ]
        [
          ''"${lib.getExe desktopControl}"''
          ''"${lib.getExe lockScreen}"''
          ''"${lib.getExe idleToggle}"''
          ''"${lib.getExe nightlightToggle}"''
          ''"${lib.getExe themeSwitcher}"''
          ''"${lib.getExe monitorToggle}"''
          ''"${lib.getExe focusOrLaunch}"''
          ''"${lib.getExe sessionExit}"''
          ''"${lib.getExe handy}"''
          ''"${config.xdg.stateHome}/theme/niri.kdl"''
          ''xcursor-theme "${config.home.pointerCursor.name}"''
          "xcursor-size ${toString config.home.pointerCursor.size}"
          ''XCURSOR_THEME "${config.home.pointerCursor.name}"''
          ''XCURSOR_SIZE "${toString config.home.pointerCursor.size}"''
        ]
        (builtins.readFile ../../config/niri/config.kdl);
    "hypr/hypridle.conf".text =
      builtins.replaceStrings [ "hyprctl dispatch dpms" ] [ (lib.getExe displayPower) ]
        (builtins.readFile ../../config/hypr/hypridle.conf);
    # Embed the packaged helper's path so keybinds also work when only the
    # Home Manager generation has been activated (useUserPackages = true).
    "hypr/hyprland.lua".text =
      builtins.replaceStrings
        [ "screenshot area" "screenshot full" "desktop-control " ]
        [ "${lib.getExe screenshot} area" "${lib.getExe screenshot} full" "${lib.getExe desktopControl} " ]
        (builtins.readFile ../../config/hypr/hyprland.lua);
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
        ExecStart = lib.getExe quickshellSession;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    niri-display-policy = lib.recursiveUpdate graphicalService {
      Unit = {
        Description = "Niri HDMI hotplug and numeric workspace ordering";
        ConditionEnvironment = "NIRI_SOCKET";
      };
      Service = {
        ExecStart = lib.getExe niriDisplayPolicy;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    hypridle = lib.recursiveUpdate graphicalService {
      Unit.Description = "Wayland idle manager";
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
      Unit = {
        Description = "Hyprland wallpaper daemon";
        ConditionEnvironment = "XDG_CURRENT_DESKTOP=Hyprland";
      };
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

    clipboard-watch-images = lib.recursiveUpdate graphicalService {
      Unit.Description = "Wayland image clipboard history watcher";
      Service = {
        ExecStart = "${lib.getExe clipboardWatch} image";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    # Super+Space in either compositor calls `handy --toggle-transcription`, which signals
    # this instance. Handy's own shortcuts are X11 grabs through XWayland and
    # only fire while an X11 window has focus.
    handy = lib.recursiveUpdate graphicalService {
      Unit = {
        Description = "Handy speech-to-text";
        After = [
          "pipewire.service"
          "wireplumber.service"
        ];
      };
      Service = {
        ExecStart = "${lib.getExe handy} --start-hidden";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
