{ isWSL, inputs, currentSystemName, ... }:
{ config, lib, pkgs, ... }:
let
  # Import the complete public environment; adapt identity and unavailable files.
  upstream = (import ../mitchellh/home-manager.nix {
    inherit isWSL inputs currentSystemName;
  }) { inherit config lib pkgs; };
  upstreamGit = upstream.programs.git;
  upstreamJj = builtins.fromTOML (builtins.readFile ../mitchellh/jujutsu.toml);
  portable = upstream // {
    home = upstream.home // {
      stateVersion = "26.05";
      # These refer to Mitchell's private 1Password vault, not to Max's account.
      sessionVariables = builtins.removeAttrs upstream.home.sessionVariables [
        "AMP_API_KEY" "OPENAI_API_KEY"
      ];
    };
    programs = upstream.programs // {
      git = upstreamGit // {
        signing = { signByDefault = false; };
        settings = lib.recursiveUpdate
          (builtins.removeAttrs upstreamGit.settings [ "user" "github" "aliases" ]) {
            user.name = "Max Miller";
            user.email = "196500602+max-miller1204@users.noreply.github.com";
            github.user = "max-miller1204";
            alias = upstreamGit.settings.aliases;
            credential.helper = "";
          };
      };
      fish = upstream.programs.fish // {
        interactiveShellInit = builtins.replaceStrings
          [ (builtins.readFile ../mitchellh/config.fish) ]
          [ (builtins.readFile ./config.fish) ]
          upstream.programs.fish.interactiveShellInit;
      };
      alacritty = upstream.programs.alacritty // {
        settings = (builtins.removeAttrs upstream.programs.alacritty.settings [ "key_bindings" ]) // {
          keyboard.bindings = [
            { key = "K"; mods = "Control|Shift"; action = "ClearHistory"; }
            { key = "V"; mods = "Control|Shift"; action = "Paste"; }
            { key = "C"; mods = "Control|Shift"; action = "Copy"; }
            { key = "Key0"; mods = "Control"; action = "ResetFontSize"; }
            { key = "Equals"; mods = "Control"; action = "IncreaseFontSize"; }
            { key = "Minus"; mods = "Control"; action = "DecreaseFontSize"; }
          ];
        };
      };
    };
    xdg = upstream.xdg // {
      configFile = upstream.xdg.configFile // {
        "i3/config" = { source = ./i3; };
        "rofi/config.rasi" = { source = ./rofi; };
        "ghostty/config" = { source = ./ghostty.linux; };
        "nvim/init.lua" = { force = false; };
        "nvim/lua" = { source = ./nvim/lua; };
      };
    };
    xresources.extraConfig = builtins.readFile ./Xresources;
  };
in {
  imports = [ portable ];
  # Ghostty is launched by his i3 config but was not in the public package list.
  # His existing Clang compiler builds LazyVim parsers; avoid a GCC bin collision.
  home.packages = with pkgs; [
    ghostty xss-lock xsetroot setxkbmap gnumake unzip wget go
  ];
  xsession.enable = true;
  home.shell.enableNushellIntegration = lib.mkForce true;
  home.pointerCursor.size = lib.mkForce 128;
  programs.neovim = {
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
  programs.nushell.extraConfig = builtins.readFile ./config.nu;
  programs.oh-my-posh = {
    settings = builtins.fromJSON (builtins.readFile ../mitchellh/omp.json);
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableNushellIntegration = true;
  };
  programs.jujutsu.settings = upstreamJj // {
    user = {
      name = "Max Miller";
      email = "196500602+max-miller1204@users.noreply.github.com";
    };
    signing = upstreamJj.signing // { behavior = "never"; };
    aliases = upstreamJj.aliases // { b = [ "bookmark" ]; };
  };
  programs.go.env.GOPRIVATE = lib.mkForce [ "github.com/max-miller1204" ];
  programs.direnv.config.whitelist = lib.mkForce {
    prefix = [ "${config.home.homeDirectory}/Developer" ];
    exact = [ "${config.home.homeDirectory}/.envrc" ];
  };
  # This single tmux Ctrl-C test passed in CI but failed in Max's VMware build.
  # Retain the same application source and the rest of the upstream test suite.
  programs.direnv-instant.package =
    (pkgs.callPackage (inputs.direnv-instant + "/default.nix") { }).overrideAttrs (old: {
      checkFlags = (old.checkFlags or [ ]) ++ [ "--skip=blocking_envrc_calls_tmux" ];
    });
}
