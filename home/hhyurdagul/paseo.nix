{ pkgs, ... }:
let
  paseo-src = pkgs.fetchurl {
    url = "https://github.com/getpaseo/paseo/releases/download/v0.8.0/Paseo-x86_64.AppImage";
    hash = "sha256-kkG2xNrnyjdQXVwwwad278XpSaMD80QN0S76ORZEzsY=";
  };
  paseo-extracted = pkgs.appimageTools.extract {
    pname = "paseo";
    version = "0.8.0";
    src = paseo-src;
  };
  paseo-wrapped = pkgs.appimageTools.wrapType2 {
    pname = "paseo";
    version = "0.8.0";
    src = paseo-src;
  };
  paseo-desktop = pkgs.symlinkJoin {
    name = "paseo-0.8.0";
    paths = [
      paseo-wrapped
      (pkgs.makeDesktopItem {
        name = "paseo";
        exec = "paseo --no-sandbox %U";
        icon = "paseo";
        desktopName = "Paseo";
        comment = "Orchestrate multiple coding agents from desktop and mobile";
        categories = [ "Development" ];
        mimeTypes = [ "x-scheme-handler/paseo" ];
        startupWMClass = "Paseo";
      })
    ];
    postBuild = ''
      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp ${paseo-extracted}/resources/app-dist/pwa-icon-512.png $out/share/icons/hicolor/512x512/apps/paseo.png
    '';
  };
in
{
  home.packages = [ paseo-desktop ];
}
