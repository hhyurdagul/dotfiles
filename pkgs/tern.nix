# Tern is waitlist-only: the tarball needs a Stencil login, so Nix can't fetch
# it. Download it by hand, then add it to the store before building:
#   nix-store --add-fixed sha256 ~/Downloads/Tern-<version>-linux-x86_64.tar.gz
# Its self-update can't write to the store; bump version and hash instead.
{
  lib,
  stdenv,
  requireFile,
  autoPatchelfHook,
  makeWrapper,
  glib,
  glib-networking,
  gsettings-desktop-schemas,
  libGL,
  libnotify,
  libpulseaudio,
  libxcb,
  libxkbcommon,
  linux-pam,
  pipewire,
  vulkan-loader,
  wayland,
  webkitgtk_4_1,
  zenity,
}:

stdenv.mkDerivation rec {
  pname = "tern";
  version = "0.9.21";
  src = requireFile {
    name = "Tern-${version}-linux-x86_64.tar.gz";
    url = "https://stencil.so";
    hash = "sha256-ZVz3+setGqwxU+TQ2f5HcsFHtb+SXVoP0Qu5vusTOt8=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [ stdenv.cc.cc.lib ];
  # dlopened at runtime, so autoPatchelf can't see them: GPU rendering,
  # Wayland/X11 input, audio, PAM for remote sessions, and WebKitGTK for
  # web page blocks.
  runtimeDependencies = [
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
  # Since 0.9.9 Tern draws with OpenGL ES on Intel iGPUs. That swapchain has
  # no alpha, so the translucent chrome flattens to grey over white, and
  # browser blocks never start loading. Vulkan keeps the transparent
  # swapchain and working pages; WGPU_BACKEND still overrides.
  # Web page blocks need what wrapGAppsHook would add: glib-networking for
  # TLS ("TLS support is not available" otherwise), and the GNOME interface
  # schemas, without which WebKitGTK gets gtk-xft-dpi -1 and renders pages at
  # a negative zoom.
  # Save/export and unsaved-tab close look up zenity (kdialog only if zenity
  # is absent). Appearance and other portal calls exec gdbus. Carly's
  # "Tern isn't in front" notices exec notify-send. None of these are in a
  # bare session PATH, so the lookup fails and the action does nothing.
  dontAutoPatchelf = true;
  postFixup = ''
    autoPatchelf $out
    HOME=$TMPDIR XDG_DATA_HOME=$TMPDIR/share $out/bin/tern register >/dev/null
    mkdir -p $out/share
    cp -r $TMPDIR/share/applications $TMPDIR/share/icons $out/share/
    wrapProgram $out/bin/tern \
      --set-default STENCIL_GPU low-power \
      --set-default WGPU_BACKEND vulkan \
      --set VK_LOADER_DRIVERS_DISABLE '*nvidia*' \
      --prefix PATH : ${
        lib.makeBinPath [
          zenity
          glib
          libnotify
        ]
      } \
      --prefix GIO_EXTRA_MODULES : ${glib-networking}/lib/gio/modules \
      --prefix XDG_DATA_DIRS : ${glib.getSchemaDataDirPath gsettings-desktop-schemas}
  '';

  meta = {
    description = "Multiplexing terminal from Stencil";
    homepage = "https://stencil.so";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "tern";
    platforms = [ "x86_64-linux" ];
  };
}
