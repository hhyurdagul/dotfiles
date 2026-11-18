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
  openmausbot = pkgs.callPackage ../../pkgs/openmausbot.nix { };

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
      (python3Packages.toPythonApplication python3Packages.trafilatura)
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
      openmausbot
      tern
      unstable.zed-editor
    ];

  # OpenMausBot writes this entry itself, but from inside its FHS sandbox it
  # sees the unwrapped -extracted binary, which can't run outside the wrapper
  # and goes stale on every update. Own the file so login uses the wrapper.
  xdg.configFile."autostart/openmausbot.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Name=OpenMausBot
      Exec=${pkgs.lib.getExe openmausbot} --omb-hidden
      NoDisplay=true
      X-GNOME-Autostart-enabled=true
      X-OpenMausBot-Lending=true
    '';
  };
}
