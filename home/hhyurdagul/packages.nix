{
  inputs,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  agents = inputs.llm-agents.packages.${system};
  unstable = inputs.nixpkgs-unstable.legacyPackages.${system};

  # The package's traced closure omits @getpaseo/server's root export, which the
  # CLI only resolves to locate the daemon entrypoint; add a stub so it resolves.
  paseo-share = pkgs.runCommand "paseo-cli-share" { } ''
    cp -r ${agents.paseo-desktop}/share/paseo-desktop $out
    chmod -R u+w $out/packages/server/dist/server/server
    echo "export {};" > $out/packages/server/dist/server/server/exports.js
  '';

  # paseo-desktop only exposes the GUI; run its bundled CLI with the same electron
  paseo-cli = pkgs.writeShellScriptBin "paseo" ''
    exec env ELECTRON_RUN_AS_NODE=1 PASEO_NODE_ENV=production \
      ${inputs.llm-agents.inputs.nixpkgs.legacyPackages.${system}.electron_42}/bin/electron \
      ${paseo-share}/packages/cli/dist/index.js "$@"
  '';

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
      codex
    ])
    ++ [
      paseo-cli
      unstable.zed-editor
    ];
}
