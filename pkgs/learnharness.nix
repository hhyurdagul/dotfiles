# Upstream ships Linux builds as an AppImage or a .deb of a bundled Electron
# app; patch the .deb. Its Next.js server runs on that same Electron
# (ELECTRON_RUN_AS_NODE) with prebuilt sharp, skia canvas and resvg addons.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libGL,
  libgbm,
  libnotify,
  libsecret,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  pango,
  systemdLibs,
}:

stdenv.mkDerivation rec {
  pname = "learnharness";
  version = "0.4.1";
  src = fetchurl {
    url = "https://github.com/amosblomqvist/learnharness/releases/download/v${version}/LearnHarness-${version}-amd64.deb";
    hash = "sha256-/AnnrB+amuJr2K2+wnkT5B4BTiwMX2q7sOIgfMpnHSY=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    wrapGAppsHook3
  ];
  buildInputs = [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libgbm
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemdLibs
  ];
  # dlopened by Electron: GL/EGL, keyring-backed safeStorage, notifications.
  runtimeDependencies = [
    libGL
    libnotify
    libsecret
  ];

  unpackPhase = "dpkg-deb -x $src .";

  # Without package-type, electron-updater falls back to its AppImage updater,
  # which stays inactive outside an AppImage instead of fetching a .deb it
  # can't install. The SUID sandbox helper can't be setuid in the store;
  # Electron uses the user-namespace sandbox instead.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share
    cp -r opt/LearnHarness $out/share/learnharness
    rm $out/share/learnharness/resources/package-type $out/share/learnharness/chrome-sandbox
    cp -r usr/share/icons $out/share/
    install -Dm644 usr/share/applications/learnharness.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/learnharness.desktop \
      --replace-fail /opt/LearnHarness/learnharness learnharness
    runHook postInstall
  '';

  # One wrapper carrying the GSettings schemas (GTK file dialogs) plus the
  # Wayland flags; gappsWrapperArgs is only filled in during fixup.
  dontWrapGApps = true;
  postFixup = ''
    makeWrapper $out/share/learnharness/learnharness $out/bin/learnharness \
      "''${gappsWrapperArgs[@]}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-wayland-ime}}"
  '';

  meta = {
    description = "Agent harness for learning difficult things";
    homepage = "https://github.com/amosblomqvist/learnharness";
    license = lib.licenses.agpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "learnharness";
    platforms = [ "x86_64-linux" ];
  };
}
