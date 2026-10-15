{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./packages.nix
    ./services.nix
    ./maintenance.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";

    sessionVariables = {
      BROWSER = "zen";
      DEFAULT_BROWSER = "zen";
      EDITOR = "hx";
      VISUAL = "hx";
      NIXOS_OZONE_WL = "1";
      PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    };

    # Breeze Light ships inside kdePackages.breeze (1.8 GiB closure with Qt and
    # KDE frameworks); copy just the cursor theme. GTK's settings.ini belongs to
    # theme-switcher, so gtk.enable stays off and that script adds the cursor.
    # Both compositor configs use this theme; Niri's size is substituted below.
    pointerCursor = {
      enable = true;
      name = "Breeze_Light";
      size = 12;
      package = pkgs.runCommand "breeze-light-cursor" { } ''
        mkdir -p $out/share/icons
        cp -r ${pkgs.kdePackages.breeze}/share/icons/Breeze_Light $out/share/icons/
      '';
    };
  };

  # GTK4 and the settings portal read the cursor from GSettings, not settings.ini.
  dconf.settings."org/gnome/desktop/interface" = {
    cursor-theme = config.home.pointerCursor.name;
    cursor-size = config.home.pointerCursor.size;
  };

  home.file.".p10k.zsh".source = ../../config/zsh/p10k.zsh;

  programs = {
    home-manager.enable = true;

    git.enable = true;

    zsh = {
      enable = true;
      enableCompletion = true;
      # Rebuild the completion dump at most once a day for faster startup.
      completionInit = ''
        autoload -Uz compinit
        setopt extendedglob
        if [[ -n ''${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
          compinit
        else
          compinit -C
        fi
      '';
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      defaultKeymap = "viins";
      autocd = true;

      history = {
        size = 50000;
        ignoreAllDups = true;
      };
      historySubstringSearch.enable = true;

      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "zsh-completions";
          src = pkgs.zsh-completions;
          completions = [ "share/zsh/site-functions" ];
        }
      ];

      initContent = lib.mkMerge [
        # Powerlevel10k instant prompt must stay at the very top of .zshrc.
        (lib.mkOrder 500 (builtins.readFile ../../config/zsh/early-init.zsh))
        (lib.mkOrder 1000 (builtins.readFile ../../config/zsh/init.zsh))
      ];
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  xdg = {
    enable = true;

    mimeApps = {
      enable = true;

      associations = {
        added = {
          "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
          "application/pdf" = [ "org.gnome.Papers.desktop" ];
          "application/zip" = [ "org.gnome.FileRoller.desktop" ];
          "application/vnd.rar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-rar" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
          "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
          "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
          "image/avif" = [ "imv.desktop" ];
          "image/bmp" = [ "imv.desktop" ];
          "image/gif" = [ "imv.desktop" ];
          "image/heic" = [ "imv.desktop" ];
          "image/heif" = [ "imv.desktop" ];
          "image/jpeg" = [ "imv.desktop" ];
          "image/png" = [ "imv.desktop" ];
          "image/svg+xml" = [ "imv.desktop" ];
          "image/tiff" = [ "imv.desktop" ];
          "image/webp" = [ "imv.desktop" ];
          "video/mp4" = [ "vlc.desktop" ];
          "video/mpeg" = [ "vlc.desktop" ];
          "video/ogg" = [ "vlc.desktop" ];
          "video/quicktime" = [ "vlc.desktop" ];
          "video/webm" = [ "vlc.desktop" ];
          "video/x-matroska" = [ "vlc.desktop" ];
          "video/x-msvideo" = [ "vlc.desktop" ];
        };
        removed = {
          "application/vnd.ms-excel" = [ "chatgpt.desktop" ];
          "application/vnd.ms-excel.sheet.macroEnabled.12" = [ "chatgpt.desktop" ];
          "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "chatgpt.desktop" ];
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ "chatgpt.desktop" ];
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "chatgpt.desktop" ];
          "text/csv" = [ "chatgpt.desktop" ];
          "text/tab-separated-values" = [ "chatgpt.desktop" ];
        };
      };

      defaultApplications = {
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
        "application/msword" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/pdf" = [ "org.gnome.Papers.desktop" ];
        "application/zip" = [ "org.gnome.FileRoller.desktop" ];
        "application/vnd.rar" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-rar" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
        "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
        "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
        "application/rtf" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-excel" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-excel.sheet.binary.macroEnabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-excel.sheet.macroEnabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-excel.template.macroEnabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-powerpoint" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-powerpoint.presentation.macroEnabled.12" = [
          "onlyoffice-desktopeditors.desktop"
        ];
        "application/vnd.ms-powerpoint.slideshow.macroEnabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-powerpoint.template.macroEnabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-word.document.macroEnabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-word.template.macroEnabled.12" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.oasis.opendocument.presentation" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.oasis.opendocument.spreadsheet" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.oasis.opendocument.text" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [
          "onlyoffice-desktopeditors.desktop"
        ];
        "application/vnd.openxmlformats-officedocument.presentationml.slideshow" = [
          "onlyoffice-desktopeditors.desktop"
        ];
        "application/vnd.openxmlformats-officedocument.presentationml.template" = [
          "onlyoffice-desktopeditors.desktop"
        ];
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [
          "onlyoffice-desktopeditors.desktop"
        ];
        "application/vnd.openxmlformats-officedocument.spreadsheetml.template" = [
          "onlyoffice-desktopeditors.desktop"
        ];
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [
          "onlyoffice-desktopeditors.desktop"
        ];
        "application/vnd.openxmlformats-officedocument.wordprocessingml.template" = [
          "onlyoffice-desktopeditors.desktop"
        ];
        "image/avif" = [ "imv.desktop" ];
        "image/bmp" = [ "imv.desktop" ];
        "image/gif" = [ "imv.desktop" ];
        "image/heic" = [ "imv.desktop" ];
        "image/heif" = [ "imv.desktop" ];
        "image/jpeg" = [ "imv.desktop" ];
        "image/png" = [ "imv.desktop" ];
        "image/svg+xml" = [ "imv.desktop" ];
        "image/tiff" = [ "imv.desktop" ];
        "image/webp" = [ "imv.desktop" ];
        "text/html" = [ "zen.desktop" ];
        "text/csv" = [ "onlyoffice-desktopeditors.desktop" ];
        "text/tab-separated-values" = [ "onlyoffice-desktopeditors.desktop" ];
        "video/mp4" = [ "vlc.desktop" ];
        "video/mpeg" = [ "vlc.desktop" ];
        "video/ogg" = [ "vlc.desktop" ];
        "video/quicktime" = [ "vlc.desktop" ];
        "video/webm" = [ "vlc.desktop" ];
        "video/x-matroska" = [ "vlc.desktop" ];
        "video/x-msvideo" = [ "vlc.desktop" ];
        "x-scheme-handler/http" = [ "zen.desktop" ];
        "x-scheme-handler/https" = [ "zen.desktop" ];
        "x-scheme-handler/about" = [ "zen.desktop" ];
        "x-scheme-handler/unknown" = [ "zen.desktop" ];
      };
    };

    configFile = {
      "darkman/config.yaml".source = ../../config/darkman/config.yaml;
      "helix/config.toml".source = ../../config/helix/config.toml;
      "helix/languages.toml".source = ../../config/helix/languages.toml;
      "hypr/hyprlock.conf".source = ../../config/hypr/hyprlock.conf;
      "kitty/kitty.conf".source = ../../config/kitty/kitty.conf;
      "kitty/dark-theme.auto.conf".source = ../../config/kitty/themes/catppuccin-mocha.conf;
      "kitty/light-theme.auto.conf".source = ../../config/kitty/themes/catppuccin-latte.conf;
      "kitty/no-preference-theme.auto.conf".source = ../../config/kitty/themes/catppuccin-mocha.conf;
      "kitty/themes" = {
        source = ../../config/kitty/themes;
        recursive = true;
      };
      # GLib launches Terminal=true entries (Helix for text files) through
      # xdg-terminal-exec; kitty isn't in its built-in fallback list.
      "xdg-terminals.list".text = ''
        kitty.desktop
      '';
      quickshell = {
        source = ../../config/quickshell;
        recursive = true;
      };
    };

    dataFile = {
      "icons/hicolor" = {
        source = ../../config/icons/hicolor;
        recursive = true;
      };
    };

    desktopEntries = {
      # Games launched from this inherit the PRIME offload env and render on the RTX.
      prismlauncher-nvidia = {
        name = "Prism Launcher (NVIDIA)";
        genericName = "Minecraft Launcher";
        comment = "Prism Launcher on the discrete NVIDIA GPU";
        exec = "nvidia-offload prismlauncher";
        icon = "org.prismlauncher.PrismLauncher";
        categories = [
          "Game"
          "ActionGame"
          "AdventureGame"
          "Simulation"
        ];
        startupNotify = true;
        terminal = false;
      };
      ms-word = {
        name = "Microsoft Word";
        genericName = "Word Processor";
        comment = "Microsoft Word Online";
        exec = "chromium --app=https://word.cloud.microsoft";
        icon = "ms-word";
        categories = [
          "Office"
          "WordProcessor"
        ];
        startupNotify = true;
        terminal = false;
      };
      ms-excel = {
        name = "Microsoft Excel";
        genericName = "Spreadsheet";
        comment = "Microsoft Excel Online";
        exec = "chromium --app=https://excel.cloud.microsoft";
        icon = "ms-excel";
        categories = [
          "Office"
          "Spreadsheet"
        ];
        startupNotify = true;
        terminal = false;
      };
      ms-powerpoint = {
        name = "Microsoft PowerPoint";
        genericName = "Presentation";
        comment = "Microsoft PowerPoint Online";
        exec = "chromium --app=https://powerpoint.cloud.microsoft";
        icon = "ms-powerpoint";
        categories = [
          "Office"
          "Presentation"
        ];
        startupNotify = true;
        terminal = false;
      };
      ms-teams = {
        name = "Microsoft Teams";
        genericName = "Chat and Collaboration";
        comment = "Microsoft Teams Online";
        exec = "chromium --app=https://teams.cloud.microsoft";
        icon = "ms-teams";
        categories = [
          "Network"
          "Chat"
          "InstantMessaging"
        ];
        startupNotify = true;
        terminal = false;
      };
    };
  };

  # One-shot cleanup for the pre-Home-Manager layout: ~/.config entries are
  # real HM-managed directories now, but two dangling darkman hook symlinks
  # (00-theme.sh -> deleted config/darkman/*-mode.d paths) may remain next to
  # the managed 00-theme hooks. Remove only symlinks pointing into the old
  # checkout path, then delete this activation once it has run everywhere.
  home.activation.removeLegacyConfigLinks = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    for target in "$HOME/.local/share/light-mode.d/00-theme.sh" "$HOME/.local/share/dark-mode.d/00-theme.sh"; do
      if [[ -L "$target" ]]; then
        case "$(readlink "$target")" in
          "$HOME/dotfiles/config/darkman/"*) rm "$target" ;;
        esac
      fi
    done
  '';

  # Keep secrets out of Home Manager values.
}
