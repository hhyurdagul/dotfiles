{
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./packages.nix
    ./paseo.nix
    ./services.nix
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
          "application/pdf" = [ "org.gnome.Papers.desktop" ];
          "image/avif" = [ "org.gnome.Loupe.desktop" ];
          "image/bmp" = [ "org.gnome.Loupe.desktop" ];
          "image/gif" = [ "org.gnome.Loupe.desktop" ];
          "image/heic" = [ "org.gnome.Loupe.desktop" ];
          "image/heif" = [ "org.gnome.Loupe.desktop" ];
          "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
          "image/png" = [ "org.gnome.Loupe.desktop" ];
          "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];
          "image/tiff" = [ "org.gnome.Loupe.desktop" ];
          "image/webp" = [ "org.gnome.Loupe.desktop" ];
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
        "application/msword" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/pdf" = [ "org.gnome.Papers.desktop" ];
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
        "image/avif" = [ "org.gnome.Loupe.desktop" ];
        "image/bmp" = [ "org.gnome.Loupe.desktop" ];
        "image/gif" = [ "org.gnome.Loupe.desktop" ];
        "image/heic" = [ "org.gnome.Loupe.desktop" ];
        "image/heif" = [ "org.gnome.Loupe.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];
        "image/tiff" = [ "org.gnome.Loupe.desktop" ];
        "image/webp" = [ "org.gnome.Loupe.desktop" ];
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
      "hypr/hypridle.conf".source = ../../config/hypr/hypridle.conf;
      "hypr/hyprlock.conf".source = ../../config/hypr/hyprlock.conf;
      "kitty/kitty.conf".source = ../../config/kitty/kitty.conf;
      "kitty/themes" = {
        source = ../../config/kitty/themes;
        recursive = true;
      };
      quickshell = {
        source = ../../config/quickshell;
        recursive = true;
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
