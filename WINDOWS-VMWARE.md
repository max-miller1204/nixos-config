# VMware Workstation on Windows

The `vm-windows` target is an x86_64 NixOS 26.05 system for Max's VMware VM.
It imports Mitchell's entire public Home Manager environment and shared VM
configuration, with a small adapter for the existing `maxm` account and Windows.
The default desktop is i3 on X11 with LightDM and VMware desktop integration.
The upstream Plasma, i3, and GNOME/IBus specialisations remain in the boot menu.

This includes the public package list, Fish plugins/prompt/functions, Bash setup,
Nushell, Atuin, Oh My Posh, Starship, Git, Jujutsu, Go/gopls, Zig, Clang, Valgrind,
Node, Neovim nightly, 1Password CLI, Chezmoi, Claude Code, Codex, Ghostty, Kitty,
Alacritty, Rofi, Chromium, Firefox, Zathura, and the original CLI utilities.
The shared VM configuration includes Docker, Tailscale, Flatpak, Snap, input
methods, SSH, and the xrandr display-size workaround.

## What cannot be copied from the public repository

His current Neovim setup loads `config.lazy`, but those Lua files are not in this
repository. At Max's request the official LazyVim starter is provided instead;
its source commit and license are recorded in `users/maxm/nvim/README.md`.
Neovim downloads its plugins on first launch. This is not a claim to reproduce
Mitchell's unavailable private editor customisations.
The Neovim wrapper supplies the Tree-sitter CLI so the starter avoids a
first-launch race in Mason's automatic Tree-sitter installation.

His passwords, SSH/GPG keys, 1Password vault references, private `devtty` script,
licensed fonts, project dotfiles, and macOS host applications are not installed.
Git/Jujutsu use Max's identity and do not require Mitchell's signing key.
The packaged account-based tools use Max's own authentication when configured.
The public Nushell and Oh My Posh files are wired up without the private vault
aliases. The Fish SSH-agent setup tolerates an account with no SSH key yet.
Oh My Posh uses the same pinned unstable package set as Nushell to avoid the
older generated prompt's string/integer command-duration mismatch. The public
prompt theme is unchanged.
Atuin's Nushell hook backports the upstream `atuin_up_arrow` binding name.
Ctrl+R and Up-arrow actions are retained, and the Atuin package version is
unchanged; this avoids the newer Nushell warning about duplicate names.

The pinned direnv-instant source is retained. Its `blocking_envrc_calls_tmux`
integration test passed on the CI host but failed in Max's VMware build waiting
for the daemon to exit after Ctrl+C. This profile skips only that test and
retains the remaining upstream tests. The tmux Ctrl+C cancellation behaviour
is therefore not validated by the adapted package build.

Disk identifiers, username/password, time zone, US keyboard layout, fonts/DPI,
cursor size, clipboard shortcuts, and the enabled firewall are adapted to this
VM. The configured Windows Downloads share is mounted read-only at
`/host/Downloads` on access. It does not block boot if sharing is disabled.

## Install on the existing VM

Run these commands inside the installed NixOS system, logged in as `maxm`.
For the initial block below, start Bash with `bash` if using Fish or Nushell;
the timestamped backup uses Bash command substitution.
The existing disk layout is preserved: copy the generated hardware file rather
than partitioning or installing NixOS again. The checked-in placeholder
intentionally prevents rebuilding until this step is complete.

First, download the configuration and save the current system configuration:

```sh
git clone https://github.com/max-miller1204/nixos-config.git ~/nixos-config
cd ~/nixos-config
sudo cp -a /etc/nixos /etc/nixos.before-fork-$(date +%Y%m%d-%H%M%S)
cp /etc/nixos/hardware-configuration.nix machines/hardware/vm-windows.nix
git add machines/hardware/vm-windows.nix
```

If you already cloned the fork, use that checkout and `git pull --ff-only` instead
of cloning it again. Preserve local edits before updating.

Build without changing the running system:

```sh
sudo nixos-rebuild build --flake '.#vm-windows'
```

If the build succeeds, install it for the next boot and reboot. This avoids
restarting the desktop midway through installation:

```sh
sudo nixos-rebuild boot --flake '.#vm-windows'
sudo reboot
```

Log in as `maxm`. Home Manager activates the user configuration at boot. It backs
up files such as the i3 wizard's configuration with `.before-home-manager`.
If this suffix already exists, activation stops rather than overwrite that
backup; move the old backup aside and restart `home-manager-maxm.service`.

## Keybindings

`Super` is the Windows key. Click inside the VM so it receives keyboard input.

| Shortcut | Action |
| --- | --- |
| Super+N | Open Ghostty |
| Super+Enter | Open Xfce Terminal as an alternative |
| Super+O | Rofi application launcher |
| Super+H/J/K/L | Focus left/down/up/right |
| Super+Shift+H/J/K/L | Move a window |
| Super+1 through Super+0 | Switch workspaces |
| Super+W | Close the focused window |
| Super+Shift+F | Toggle the focused i3 window's fullscreen mode |
| Super+R | Resize/move mode; Escape leaves the mode |
| Super+Backspace | Logout/reboot/shutdown menu |
| Super+Ctrl+F | Reapply the preferred display resolution |

Terminal copy/paste uses Ctrl+Shift+C and Ctrl+Shift+V.
These are Mitchell's keybindings, so Super+D is a split command, not the launcher.

## VMware fullscreen sizing

In VMware, enable **View > Autosize > Autofit Guest**. Also select
**Edit > Preferences > Display > Full screen > Autofit guest (change guest resolution)**,
then press **Ctrl+Alt+Enter** to enter VMware fullscreen. A maximized VMware window is
still windowed; Super+Shift+F only changes the focused window inside i3.
The desktop tools normally update the resolution as the window changes size.
If the guest remains small or has borders, run `xrandr-auto` inside the VM or
press Super+Ctrl+F. The helper discovers connected outputs instead of assuming
the output is named `Virtual-1`, and also runs once when i3 starts.
This includes the workaround; fullscreen behaviour still needs verification
in the actual VMware GUI. The Apple Silicon/Fusion-specific resolution comment
in the upstream i3 module does not establish a fix for Windows Workstation.

At Max's request, display settings match Mitchell's public configuration:
Xft uses 180 DPI, Rofi uses 220 DPI, i3 uses Fira Code 8, and the cursor is
128 pixels. Rofi uses Fira Code 12 in place of the unavailable licensed
Monaco font. Log out and back in after changing scaling so newly launched
applications inherit it.
To preview the text size before rebuilding, run:

```sh
printf 'Xft.dpi: 180\n' | xrdb -merge
i3-msg restart
```

This preview lasts for the current session; the Home Manager configuration
makes it persistent after installing the updated profile.

## Verify and update

```sh
printenv XDG_SESSION_TYPE
systemctl is-active vmware
systemctl is-active home-manager-maxm
systemctl --failed --no-pager
```

Expected: `x11`, `active`, `active`, and no failed units.
Clipboard sharing also requires VMware Guest Isolation copy/paste enabled.
The profile explicitly sets `virtualisation.vmware.guest.headless = false`.

For subsequent updates, use `git pull --ff-only`, then build and run
`sudo nixos-rebuild boot --flake '.#vm-windows'` from this checkout.
The original Makefile's default target is ARM; specify
`make switch NIXNAME=vm-windows` if using it for an immediate switch.

The GitHub Actions check builds the entire profile (including desktop
specialisations) using a CI-only hardware fixture, validates i3/Rofi/Ghostty and
shell configuration, exercises the display helper under a virtual X server,
and launches Neovim headlessly to bootstrap LazyVim. It cannot verify VMware's
GUI behaviour or log in to Max's external accounts. Your actual hardware file
still needs a build inside the VM. If a new generation fails to boot, select
the previous working generation from the NixOS boot menu.
