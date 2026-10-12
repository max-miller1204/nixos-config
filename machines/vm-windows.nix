{ pkgs, ... }: {
  # Keep this profile independent of Mitchell's Apple Silicon machine settings.
  imports = [ ./hardware/vm-windows.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.consoleMode = "0";
  boot.loader.timeout = 5;
  networking.hostName = "nixos-dev";
  networking.networkmanager.enable = true;
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  users.mutableUsers = true;
  security.sudo.wheelNeedsPassword = true;

  # Desktop tools are required for clipboard sharing; the system service alone
  # is insufficient. The NixOS module starts the desktop helper in X11 sessions.
  virtualisation.vmware.guest = {
    enable = true;
    headless = false;
  };
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    displayManager.lightdm.enable = true;
    desktopManager.xterm.enable = false;
    windowManager.i3.enable = true;
  };
  services.displayManager.defaultSession = "none+i3";

  # Back up the configuration created by the i3 wizard rather than overwrite it.
  home-manager.backupFileExtension = "before-home-manager";
  fonts.packages = with pkgs; [ fira-code jetbrains-mono ];
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
  virtualisation.docker.enable = true;
  environment.systemPackages = with pkgs; [ gtkmm3 xfce4-terminal xclip ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "26.05";
}
