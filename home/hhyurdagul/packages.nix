{
  inputs,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  agents = inputs.llm-agents.packages.${system};
  unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
  zenBrowser = inputs.zen-browser.packages.${system}.default;

  tern = pkgs.callPackage ../../pkgs/tern.nix { };
  learnharness = pkgs.callPackage ../../pkgs/learnharness.nix { };

in
{
  home.packages =
    (with pkgs; [
      # Desktop applications
      adw-gtk3
      blender
      chromium
      darkman
      file-roller
      unar
      fuzzel
      godot
      kitty
      kooha
      libnotify
      libreoffice
      imv
      (thunar.override { thunarPlugins = [ thunar-archive-plugin ]; })
      networkmanagerapplet
      obsidian
      obs-studio
      onlyoffice-desktopeditors
      papers
      prismlauncher
      pavucontrol
      quickshell
      satty
      solaar
      vlc

      # Wayland and media integration
      brightnessctl
      cliphist
      ddcutil
      grim
      playerctl
      slurp
      wl-clipboard
      xdg-terminal-exec
      wlsunset

      # Hyprland helpers
      hypridle
      hyprpaper

      # CLI and development tools
      age
      bat
      btop
      bubblewrap
      eza
      fd
      fzf
      helix
      jq
      lazydocker
      lazygit
      nixd
      nixfmt
      podman-compose
      psmisc
      python3
      ripgrep
      sops
      typst
      uv
      wget
      yazi
      zoxide
    ])
    ++ [
      zenBrowser
    ]
    ++ (with agents; [
      antigravity-cli
      antigravity-hub
      chatgpt
      claude-code
      claude-desktop
      grok
      omp
      pi
      prime-agent
      grok-bot
      ccusage
      herdr
      t3code
      t3code-desktop
      codex
    ])
    ++ [
      learnharness
      tern
      unstable.zed-editor
    ];
}
