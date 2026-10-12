{ inputs, ... }:
{ pkgs, ... }: {
  home.stateVersion = "26.05";
  home.packages = with pkgs; [ bat eza fd fzf gh htop jq ripgrep tree nodejs go ];
  home.sessionVariables.EDITOR = "nvim";
  home.sessionPath = [ "$HOME/.local/bin" ];
  xdg.enable = true;
  programs.bash.enable = true;
  programs.fish = {
    enable = true;
    shellAliases = {
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
      pbcopy = "clip.exe";
      pbpaste = "powershell.exe -NoProfile -Command Get-Clipboard";
    };
    interactiveShellInit = ''
      set -g fish_greeting
      set -g theme_color_scheme dracula
    '';
    plugins = [{ name = "bobthefish"; src = inputs.theme-bobthefish; }];
  };
  programs.git = {
    enable = true;
    settings = {
      user.name = "Max Miller";
      user.email = "196500602+max-miller1204@users.noreply.github.com";
      init.defaultBranch = "main";
    };
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    initLua = ''
      vim.opt.number = true
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.termguicolors = true
    '';
  };
  programs.direnv = { enable = true; nix-direnv.enable = true; };
}
