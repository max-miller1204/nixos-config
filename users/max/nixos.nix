{ pkgs, ... }: {
  environment.pathsToLink = [ "/share/fish" ];
  environment.localBinInPath = true;
  environment.systemPackages = with pkgs; [ git gnumake ];
  programs.fish.enable = true;
  programs.nix-ld.enable = true;
  users.users.max = {
    isNormalUser = true;
    home = "/home/max";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.fish;
  };
  security.sudo.wheelNeedsPassword = true;
}
