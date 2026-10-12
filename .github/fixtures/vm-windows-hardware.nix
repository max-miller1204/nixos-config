# For CI only. Installation must use the VM's generated hardware configuration.
{ ... }: {
  boot.initrd.availableKernelModules = [ "mptspi" "ahci" "sd_mod" ];
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos-ci";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot-ci";
    fsType = "vfat";
  };
  swapDevices = [];
  nixpkgs.hostPlatform = "x86_64-linux";
}
