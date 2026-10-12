{ lib, pkgs, ... }: {
  # Reuse the complete shared VM environment and its desktop specialisations.
  imports = [ ./hardware/vm-windows.nix ./vm-shared.nix ];
  boot.loader.timeout = 5;
  networking.hostName = lib.mkForce "nixos-dev";
  networking.networkmanager.enable = true;
  time.timeZone = lib.mkForce "America/New_York";
  users.mutableUsers = lib.mkForce true;
  security.sudo.wheelNeedsPassword = lib.mkForce true;
  networking.firewall.enable = lib.mkForce true;
  system.stateVersion = lib.mkForce "26.05";

  virtualisation.vmware.guest = {
    enable = true;
    headless = false;
  };
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    displayManager.lightdm.enable = lib.mkDefault true;
    displayManager.sessionCommands = ''
      ${pkgs.xset}/bin/xset r rate 200 40
    '';
    desktopManager.xterm.enable = false;
    windowManager.i3.enable = lib.mkDefault true;
  };
  services.displayManager.defaultSession = lib.mkDefault "none+i3";

  # The other upstream desktop choices remain selectable from the boot menu.
  specialisation.plasma.configuration = {
    services.xserver.windowManager.i3.enable = false;
    services.xserver.displayManager.lightdm.enable = false;
    services.displayManager.defaultSession = null;
  };
  specialisation."gnome-ibus".configuration = {
    services.xserver.windowManager.i3.enable = false;
    services.xserver.displayManager.lightdm.enable = false;
    services.displayManager.defaultSession = null;
  };
  home-manager.backupFileExtension = "before-home-manager";
  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };
  programs.firefox.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # The configured host share appears at /host/Downloads. Automounting avoids
  # blocking boot if shared folders are disabled in VMware.
  fileSystems."/host" = {
    device = ".host:/";
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    options = [ "ro" "allow_other" "umask=022" "nofail" "noauto" "x-systemd.automount" ];
  };
  environment.systemPackages = with pkgs; [ gtkmm3 xfce4-terminal ];
  nix.settings.substituters = lib.mkForce [
    "https://cache.nixos.org"
    "https://mitchellh-nixos-config.cachix.org"
    "https://nix-community.cachix.org"
  ];
  nix.settings.trusted-public-keys = lib.mkForce [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "mitchellh-nixos-config.cachix.org-1:bjEbXJyLrL1HZZHBbO4QALnI5faYZppzkU4D2s0G8RQ="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
}
