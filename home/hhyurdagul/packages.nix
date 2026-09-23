{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  agents = inputs.llm-agents.packages.${system};
in
{
  home.packages =
    (with pkgs; [
      # Desktop applications
      adw-gtk3
      blender
      chromium
      darkman
      fuzzel
      godot
      kitty
      libnotify
      loupe
      nautilus
      networkmanagerapplet
      obsidian
      onlyoffice-desktopeditors
      papers
      pavucontrol
      quickshell
      vlc
      hyprlock

      # Wayland and media integration
      brightnessctl
      cliphist
      ddcutil
      grim
      playerctl
      slurp
      wl-clipboard
      wlsunset

      # Hyprland helpers
      hypridle
      hyprpaper

      # CLI and development tools
      age
      bat
      btop
      eza
      fd
      fzf
      helix
      jq
      lazydocker
      lazygit
      nixd
      playwright-driver
      podman-compose
      psmisc
      ripgrep
      sops
      typst
      uv
      wget
      yazi
      zoxide
    ])
    ++ [
      inputs.zen-browser.packages.${system}.default
    ]
    ++ (with agents; [
      antigravity-cli
      chatgpt
      claude-code
      claude-desktop
      grok
      omp
      pi
      grok-bot
      hermes-agent
      hermes-desktop
      ccusage
      herdr
      paseo-desktop
      voxtype
    ]);
}
