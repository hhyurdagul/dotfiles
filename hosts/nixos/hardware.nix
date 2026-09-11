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
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
      };
    };

    nvidia-container-toolkit.enable = true;
  };

  services = {
    xserver.videoDrivers = [
      "modesetting"
      "nvidia"
    ];
    fstrim.enable = true;
    fwupd.enable = true;
    hardware.bolt.enable = true;
    thermald.enable = true;
  };
  # Let RTD3 runtime-suspend the dGPU (display + audio functions) when idle.
  # Driver already reports fine-grained PM with video memory off; this keeps
  # PCI power control on auto so nothing pins it to D0.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03*", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x04*", TEST=="power/control", ATTR{power/control}="auto"
  '';

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
