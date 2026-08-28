{ inputs, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Istanbul";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "tr_TR.UTF-8";
      LC_IDENTIFICATION = "tr_TR.UTF-8";
      LC_MEASUREMENT = "tr_TR.UTF-8";
      LC_MONETARY = "tr_TR.UTF-8";
      LC_NAME = "tr_TR.UTF-8";
      LC_NUMERIC = "tr_TR.UTF-8";
      LC_PAPER = "tr_TR.UTF-8";
      LC_TELEPHONE = "tr_TR.UTF-8";
      LC_TIME = "tr_TR.UTF-8";
    };
  };

  services = {
    xserver.xkb = {
      layout = "tr";
      variant = "";
    };
    fstrim.enable = true;
    openssh = {
      enable = true;
      settings.PermitRootLogin = "no";
    };
  };

  console.keyMap = "trq";

  programs = {
    git.enable = true;
    zsh.enable = true;
  };

  users = {
    defaultUserShell = pkgs.zsh;
    users.hhyurdagul = {
      isNormalUser = true;
      description = "Hasan Hüseyin Yurdagül";
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  environment.systemPackages = with pkgs; [
    wget
    helix
    fzf
    ripgrep
    inputs.helium.packages.${system}.default
  ];

  system.stateVersion = "26.05";
}
