{ pkgs, ... }: {
  environment.pathsToLink = [ "/share/fish" ];
  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [ git gnumake ];
  programs.fish.enable = true;
  programs.nix-ld.enable = true;
  users.users.max = {
    isNormalUser = true;
    home = "/home/max";
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
  };
  # WSL login is controlled by the Windows account. Set a Linux password
  # before enabling password-required sudo.
  security.sudo.wheelNeedsPassword = false;
}
