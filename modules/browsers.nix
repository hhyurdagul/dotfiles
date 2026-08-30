{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    helium
    zen-browser
  ];

  environment.sessionVariables = {
    DEFAULT_BROWSER = "zen";
    BROWSER = "zen";
  };

  xdg.mime = {
    enable = true;
    defaultApplications = {
      "text/html" = "zen.desktop";
      "x-scheme-handler/http" = "zen.desktop";
      "x-scheme-handler/https" = "zen.desktop";
      "x-scheme-handler/about" = "zen.desktop";
      "x-scheme-handler/unknown" = "zen.desktop";
    };
  };
}
