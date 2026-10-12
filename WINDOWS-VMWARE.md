# VMware Workstation on Windows

The `vm-windows` target is an x86_64 NixOS 26.05 system for Max's VMware VM.
It keeps the existing `maxm` account and password and uses i3 on X11 with
LightDM, VMware desktop tools, Ghostty, Rofi, Fish, Neovim, and development tools.
The i3 colors and keybindings are adapted from Mitchell's configuration. Private
scripts and his international keyboard layout are omitted. Fonts and DPI suit
a standard Windows display rather than an Apple Retina VM.

## Install on the existing VM

Run these commands inside the installed NixOS system, logged in as `maxm`.
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
sudo nixos-rebuild build --flake .#vm-windows
```

If the build succeeds, install it for the next boot and reboot. This avoids
restarting the desktop midway through installation:

```sh
sudo nixos-rebuild boot --flake .#vm-windows
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
| Super+Shift+F | Toggle fullscreen |
| Super+R | Resize/move mode; Escape leaves the mode |
| Super+Backspace | Logout/reboot/shutdown menu |

Terminal copy/paste uses Ctrl+Shift+C and Ctrl+Shift+V.
These are Mitchell's keybindings, so Super+D is a split command, not the launcher.

## Verify and update

```sh
echo "$XDG_SESSION_TYPE"
systemctl is-active vmware
systemctl is-active home-manager-maxm
systemctl --failed --no-pager
```

Expected: `x11`, `active`, `active`, and no failed units.
Clipboard sharing also requires VMware Guest Isolation copy/paste enabled.
The profile explicitly sets `virtualisation.vmware.guest.headless = false`.

For subsequent updates, use `git pull --ff-only`, then build and run
`sudo nixos-rebuild boot --flake .#vm-windows` from this checkout.
The original Makefile's default target is ARM; specify
`make switch NIXNAME=vm-windows` if using it for an immediate switch.

The GitHub Actions check builds the entire profile using a CI-only hardware
fixture and validates the i3 and Rofi configuration. Your actual hardware file
still needs a build inside the VM. If a new generation fails to boot, select the
previous working generation from the NixOS boot menu.
