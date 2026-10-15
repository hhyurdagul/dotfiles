{
  inputs,
  lib,
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

  # Tern is waitlist-only: the tarball needs a Stencil login, so Nix can't fetch
  # it. Download it by hand, then add it to the store before building:
  #   nix-store --add-fixed sha256 ~/Downloads/Tern-<version>-linux-x86_64.tar.gz
  # Its self-update can't write to the store; bump version and hash instead.
  tern = pkgs.stdenv.mkDerivation rec {
    pname = "tern";
    version = "0.8.3";
    src = pkgs.requireFile {
      name = "Tern-${version}-linux-x86_64.tar.gz";
      url = "https://stencil.so";
      hash = "sha256-vMICgHolxxhYVhofV+A95F+94ZE4STAuNKLwo2xs/nk=";
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];
    # dlopened at runtime, so autoPatchelf can't see them: GPU rendering,
    # Wayland/X11 input, audio, PAM for remote sessions, and WebKitGTK for
    # web page blocks.
    runtimeDependencies = with pkgs; [
      libGL
      libpulseaudio
      libxcb
      libxkbcommon
      linux-pam
      pipewire
      vulkan-loader
      wayland
      webkitgtk_4_1
    ];

    installPhase = ''
      runHook preInstall
      install -Dm755 tern $out/bin/tern
      runHook postInstall
    '';

    # A store-installed Tern leaves desktop entries and icons to its package.
    # `tern register` writes them into a scratch HOME; ship those. The binary
    # only runs once patched, so patch here instead of in the default hook.
    # Wrap after registering so the entries keep pointing at bin/tern.
    # wgpu defaults to the discrete GPU, which keeps the NVIDIA card awake and
    # copies every frame to the Intel side that drives the display. Use the
    # iGPU unless STENCIL_GPU says otherwise.
    # Web page blocks need what wrapGAppsHook would add: glib-networking for
    # TLS ("TLS support is not available" otherwise), and the GNOME interface
    # schemas, without which WebKitGTK gets gtk-xft-dpi -1 and renders pages at
    # a negative zoom.
    dontAutoPatchelf = true;
    postFixup = ''
      autoPatchelf $out
      HOME=$TMPDIR XDG_DATA_HOME=$TMPDIR/share $out/bin/tern register >/dev/null
      mkdir -p $out/share
      cp -r $TMPDIR/share/applications $TMPDIR/share/icons $out/share/
      wrapProgram $out/bin/tern \
        --set-default STENCIL_GPU low-power \
        --prefix GIO_EXTRA_MODULES : ${pkgs.glib-networking}/lib/gio/modules \
        --prefix XDG_DATA_DIRS : ${pkgs.glib.getSchemaDataDirPath pkgs.gsettings-desktop-schemas}
    '';

    meta = {
      description = "Multiplexing terminal from Stencil";
      homepage = "https://stencil.so";
      license = lib.licenses.unfree;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      mainProgram = "tern";
      platforms = [ "x86_64-linux" ];
    };
  };

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
      libnotify
      libreoffice
      imv
      nautilus
      networkmanagerapplet
      obsidian
      obs-studio
      onlyoffice-desktopeditors
      papers
      prismlauncher
      pavucontrol
      quickshell
      satty
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
      deadnix
      eza
      fd
      fzf
      helix
      jq
      lazydocker
      lazygit
      nixd
      nixfmt
      playwright-driver
      podman-compose
      psmisc
      python3
      ripgrep
      sops
      statix
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
      ccusage
      herdr
      paseo-desktop
      codex
    ])
    ++ [
      paseo-cli
      tern
      unstable.zed-editor
    ];
}
