{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  # MIME types grouped by the app that should open them.
  withApp = app: types: lib.genAttrs types (_: [ app ]);
  archiveTypes = [
    "application/zip"
    "application/vnd.rar"
    "application/x-rar"
    "application/x-7z-compressed"
    "application/x-tar"
    "application/gzip"
  ];
  imageTypes = map (t: "image/${t}") [
    "avif"
    "bmp"
    "gif"
    "heic"
    "heif"
    "jpeg"
    "png"
    "svg+xml"
    "tiff"
    "webp"
  ];
  videoTypes = map (t: "video/${t}") [
    "mp4"
    "mpeg"
    "ogg"
    "quicktime"
    "webm"
    "x-matroska"
    "x-msvideo"
  ];
  officeTypes = [
    "application/msword"
    "application/rtf"
    "application/vnd.ms-excel"
    "application/vnd.ms-excel.sheet.binary.macroEnabled.12"
    "application/vnd.ms-excel.sheet.macroEnabled.12"
    "application/vnd.ms-excel.template.macroEnabled.12"
    "application/vnd.ms-powerpoint"
    "application/vnd.ms-powerpoint.presentation.macroEnabled.12"
    "application/vnd.ms-powerpoint.slideshow.macroEnabled.12"
    "application/vnd.ms-powerpoint.template.macroEnabled.12"
    "application/vnd.ms-word.document.macroEnabled.12"
    "application/vnd.ms-word.template.macroEnabled.12"
    "application/vnd.oasis.opendocument.presentation"
    "application/vnd.oasis.opendocument.spreadsheet"
    "application/vnd.oasis.opendocument.text"
    "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    "application/vnd.openxmlformats-officedocument.presentationml.slideshow"
    "application/vnd.openxmlformats-officedocument.presentationml.template"
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    "application/vnd.openxmlformats-officedocument.spreadsheetml.template"
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    "application/vnd.openxmlformats-officedocument.wordprocessingml.template"
    "text/csv"
    "text/tab-separated-values"
  ];
  browserTypes = [
    "text/html"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
  ];
  # Also listed under associations.added, so these apps are offered first in
  # "Open With" even where another app registers the type.
  fileApps =
    withApp "thunar.desktop" [ "inode/directory" ]
    // withApp "org.gnome.Papers.desktop" [ "application/pdf" ]
    // withApp "org.gnome.FileRoller.desktop" archiveTypes
    // withApp "imv.desktop" imageTypes
    // withApp "vlc.desktop" videoTypes;
in
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
      # Vulkan and wgpu otherwise pick the RTX and keep it awake. nvidia-offload
      # unsets this. GL stays on the iGPU unless that wrapper selects NVIDIA.
      VK_LOADER_DRIVERS_DISABLE = "*nvidia*";
    };

    # Breeze Light ships inside kdePackages.breeze (1.8 GiB closure with Qt and
    # KDE frameworks); copy just the cursor theme. GTK's settings.ini belongs to
    # theme-switcher, so gtk.enable stays off and that script adds the cursor.
    # Both compositor configs use this theme; Niri's size is substituted below.
    pointerCursor = {
      enable = true;
      name = "Breeze_Light";
      size = 16;
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
        added = fileApps;
        # ChatGPT registers office and table types; keep it out of "Open With".
        removed = withApp "chatgpt.desktop" [
          "application/vnd.ms-excel"
          "application/vnd.ms-excel.sheet.macroEnabled.12"
          "application/vnd.openxmlformats-officedocument.presentationml.presentation"
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
          "text/csv"
          "text/tab-separated-values"
        ];
      };

      defaultApplications =
        fileApps
        // withApp "onlyoffice-desktopeditors.desktop" officeTypes
        // withApp "zen.desktop" browserTypes;
    };

    configFile = {
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
      # Tern loads <plugins>/<id>.path as an absolute package directory.
      # Forwards inbox events to Quickshell; Tern's own banners stay in-app.
      "tern/plugins/desktop-notify.path".text = "${../../config/tern/desktop-notify}\n";
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

  # Keep secrets out of Home Manager values.
}
