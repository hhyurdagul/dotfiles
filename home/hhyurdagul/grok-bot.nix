{ pkgs, ... }:
let
  grok-bot-src = pkgs.fetchurl {
    url = "https://downloads.cursor.com/grokbot/stable/c4074f405d36a56b406f11cc6485404ff8b395eb/linux/x64/Grok_Bot_0.57.1.AppImage";
    hash = "sha256-Hz2P1GElUgsbDrYxLCzBs63yyGyZjC4wob/tT0xMRvQ=";
  };
  grok-bot-extracted = pkgs.appimageTools.extract {
    pname = "grok-bot";
    version = "0.57.1";
    src = grok-bot-src;
  };
  grok-bot-wrapped = pkgs.appimageTools.wrapType2 {
    pname = "grok-bot";
    version = "0.57.1";
    src = grok-bot-src;
  };
  grok-bot-desktop = pkgs.symlinkJoin {
    name = "grok-bot-0.57.1";
    paths = [
      grok-bot-wrapped
      (pkgs.makeDesktopItem {
        name = "grok-bot";
        exec = "grok-bot --no-sandbox %U";
        icon = "grok-bot";
        desktopName = "Grok Bot";
        comment = "Grok Bot desktop agent";
        categories = [ "Development" ];
        mimeTypes = [
          "x-scheme-handler/grokbot"
          "x-scheme-handler/sand"
        ];
        startupWMClass = "grok-bot";
      })
    ];
    postBuild = ''
      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp ${grok-bot-extracted}/resources/icon.png $out/share/icons/hicolor/512x512/apps/grok-bot.png
    '';
  };
in
{
  home.packages = [ grok-bot-desktop ];
}
