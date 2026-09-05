{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  home.packages =
    (with pkgs; [
      # Desktop applications
      adw-gtk3
      darkman
      fuzzel
      kitty
      libnotify
      nautilus
      networkmanagerapplet
      obsidian
      onlyoffice-desktopeditors
      pavucontrol
      quickshell
      swaylock-effects

      # Wayland and media integration
      brightnessctl
      cliphist
      ddcutil
      grim
      playerctl
      slurp
      wl-clipboard
      wlsunset

      # Hyprland helpers. Hyprpaper stays available but is not started until
      # a wallpaper is configured.
      hypridle
      hyprpaper

      # CLI and development tools
      age
      btop
      fzf
      helix
      jq
      lazydocker
      lazygit
      nh
      nixd
      podman-compose
      psmisc
      ripgrep
      sops
      typst
      wget
      yazi
    ])
    ++ [
      inputs.helium.packages.${system}.default
      inputs.zen-browser.packages.${system}.default
      inputs.antigravity.packages.${system}.google-antigravity-cli
      inputs.codex.packages.${system}.default
      inputs.herdr.packages.${system}.default
      inputs.hermes.packages.${system}.default
      inputs.omp.packages.${system}.default
    ];
}
