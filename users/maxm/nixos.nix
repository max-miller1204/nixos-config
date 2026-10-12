{ pkgs, ... }: {
  environment.pathsToLink = [ "/share/fish" ];
  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [ git gnumake ];
  programs.fish.enable = true;
  programs.nix-ld.enable = true;
  users.users.maxm = {
    isNormalUser = true;
    home = "/home/maxm";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish;
  };
  security.sudo.wheelNeedsPassword = true;
}
