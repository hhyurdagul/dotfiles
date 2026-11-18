{
  config,
  pkgs,
  ...
}:

let
  smartAlert = pkgs.writeShellApplication {
    name = "maintenance-smart-alert";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      util-linux
    ];
    text = builtins.readFile ../../config/scripts/maintenance-smart-alert.sh;
  };
in
{
  hardware = {
    enableRedistributableFirmware = true;
    firmware = [ pkgs.sof-firmware ];
    cpu.intel.npu.enable = true;

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
        # nvidia-offload comes from home/hhyurdagul/services.nix, which also
        # undoes the session's Vulkan NVIDIA disable.
        offload.enable = true;
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
    smartd = {
      enable = true;
      autodetect = true;
      # Use smartd's supported exec hook rather than a root process depending on
      # a running Wayland notification server. Alerts survive logged-out sessions.
      defaults.monitored = "-a -n standby,q -m <nomailer> -M exec ${smartAlert}/bin/maintenance-smart-alert -M diminishing";
      notifications = {
        mail.enable = false;
        wall.enable = false;
        x11.enable = false;
      };
    };
    hardware.bolt.enable = true;
    thermald.enable = true;

    # Lenovo conservation mode caps long-term charge to protect the battery.
    # Applied when ideapad_acpi binds, so it can't race the module load.
    udev.extraRules = ''
      ACTION=="add|bind", SUBSYSTEM=="platform", DRIVER=="ideapad_acpi", TEST=="conservation_mode", ATTR{conservation_mode}="1"
    '';
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  systemd = {
    # Without a monitored slice oomd watches nothing; user slices cover every
    # niri app scope and rootless podman container, so a swap storm kills the
    # offending scope instead of freezing the session.
    oomd = {
      enable = true;
      enableUserSlices = true;
    };
    tmpfiles.rules = [
      "d /var/lib/workstation-maintenance 0755 root root -"
      "d /var/lib/workstation-maintenance/smart 0755 root root -"
    ];
  };
}
