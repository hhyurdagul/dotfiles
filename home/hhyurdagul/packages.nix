{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages =
    (with pkgs; [
      # Desktop applications
      adw-gtk3
      chromium
      darkman
      fuzzel
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
      inputs.antigravity.packages.${system}.google-antigravity-cli
      inputs.chatgpt-nix.packages.${system}.default
      inputs.codex.packages.${system}.default
      inputs.herdr.packages.${system}.default
      inputs.omp.packages.${system}.default
    ];
}
