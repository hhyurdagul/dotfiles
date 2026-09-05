{
  inputs,
  lib,
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

  programs = {
    home-manager.enable = true;

    git.enable = true;

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
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
