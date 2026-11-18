# MausBot desktop app (Electron), from the upstream AppImage. Used here as a
# client for the MausBot server on the VPS (＋ → Connect to a server).
# Its self-update can't write to the store; bump version and hash instead.
{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "openmausbot";
  version = "0.1.160";
  src = fetchurl {
    url = "https://github.com/milind-soni/OpenMausBot/releases/download/v${version}/OpenMausBot-${version}-x86_64.AppImage";
    hash = "sha256-JzoYsYDd2YK+9ogIxoYdoDGK/7uJQ++vFumQbhQAwQs=";
  };
  contents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${contents}/com.openmausbot.app.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/com.openmausbot.app.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}'
    cp -r ${contents}/usr/share/icons $out/share/
  '';

  meta = {
    description = "Desktop chat app for a team of AI agents";
    homepage = "https://docs.openmausbot.com";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "openmausbot";
    platforms = [ "x86_64-linux" ];
  };
}
