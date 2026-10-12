# Replace this file with /etc/nixos/hardware-configuration.nix generated
# by the graphical installer before applying the vm-windows configuration.
{ ... }: {
  assertions = [{
    assertion = false;
    message = "Copy /etc/nixos/hardware-configuration.nix to machines/hardware/vm-windows.nix, then git add that file before rebuilding.";
  }];
}
