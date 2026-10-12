{ lib, pkgs, ... }: {
  imports = [ ./hardware/vm-windows.nix ./vm-shared.nix ];
  networking.hostName = lib.mkForce "nixos-dev";
  networking.useDHCP = lib.mkForce true;
  time.timeZone = lib.mkForce "America/New_York";
  users.mutableUsers = lib.mkForce true;
  security.sudo.wheelNeedsPassword = lib.mkForce true;
  virtualisation.vmware.guest.enable = true;
  environment.systemPackages = with pkgs; [ gtkmm3 firefox xfce4-terminal ];
  # Use the standard NixOS cache and avoid unrelated upstream services.
  nix.settings.substituters = lib.mkForce [ "https://cache.nixos.org" ];
  nix.settings.trusted-public-keys = lib.mkForce [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];
  services.snap.enable = lib.mkForce false;
  services.tailscale.enable = lib.mkForce false;
  networking.firewall.enable = lib.mkForce true;
  services.openssh.settings.PasswordAuthentication = lib.mkForce false;
  system.stateVersion = lib.mkForce "26.05";
}
