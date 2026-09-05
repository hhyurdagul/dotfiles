{
  config,
  pkgs,
  ...
}:

{
  hardware = {
    enableRedistributableFirmware = true;
    firmware = [ pkgs.sof-firmware ];

    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      powerManagement = {
        enable = true;
        finegrained = true;
      };

      prime = {
        intelBusId = "PCI:0@0:2:0";
        nvidiaBusId = "PCI:1@0:0:0";
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
      };
    };

    nvidia-container-toolkit.enable = true;
  };

  services = {
    xserver.videoDrivers = [ "nvidia" ];
    fstrim.enable = true;
    fwupd.enable = true;
    hardware.bolt.enable = true;
    thermald.enable = true;
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  systemd.oomd.enable = true;

  systemd.services.lenovo-conservation-mode = {
    description = "Enable Lenovo battery conservation mode";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    wants = [ "systemd-udev-settle.service" ];
    unitConfig.ConditionPathExists = "/sys/class/power_supply/BAT0/extensions/ideapad_laptop/conservation_mode";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      echo 1 > /sys/class/power_supply/BAT0/extensions/ideapad_laptop/conservation_mode
    '';
  };
}
