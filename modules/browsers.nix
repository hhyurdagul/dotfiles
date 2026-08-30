{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    helium
  ];
}
