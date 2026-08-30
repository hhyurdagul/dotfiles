{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    helium
    zen-browser
  ];
}
