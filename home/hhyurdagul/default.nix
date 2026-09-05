{
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./packages.nix
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
      defaultApplications = {
        "text/html" = [ "zen.desktop" ];
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
      "hypr/hyprland.lua".source = ../../config/hypr/hyprland.lua;
      "kitty/kitty.conf".source = ../../config/kitty/kitty.conf;
      "kitty/themes" = {
        source = ../../config/kitty/themes;
        recursive = true;
      };
      quickshell = {
        source = ../../config/quickshell;
        recursive = true;
      };
      "swaylock/config".source = ../../config/swaylock/config;
    };
  };

  home.activation.removeLegacyConfigLinks = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    for path in darkman helix hypr kitty quickshell scripts swaylock; do
      target="$HOME/.config/$path"
      if [[ -L "$target" && "$(readlink "$target")" == "$HOME/dotfiles/config/$path" ]]; then
        rm "$target"
      fi
    done

    for mode in light-mode.d dark-mode.d; do
      target="$HOME/.local/share/$mode"
      if [[ -L "$target" && "$(readlink "$target")" == "$HOME/dotfiles/config/darkman/$mode" ]]; then
        rm "$target"
      fi
    done
  '';

  # Keep secrets out of Home Manager values.
}
