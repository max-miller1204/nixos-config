# VMware Workstation on Windows

This fork's `vm-windows` target runs x86_64 NixOS in VMware Workstation.
It uses Max's account and development tools, VMware guest integration,
and the upstream GNOME desktop with optional i3 and Plasma boot entries.

## Install the VM

1. Boot the prepared `NixOS-Dev.vmx` VM from the NixOS 26.05 graphical ISO.
2. Open the graphical installer. Select English and America/New_York.
3. Create the username `max` and choose your own password. Select GNOME.
4. Install to the VM's empty 150 GB disk using the erase-disk option.
   This disk belongs to the new VM. Do not select host disks or shared storage.
5. Shut down after installation, disconnect the virtual CD/DVD ISO in VMware,
   then boot from the installed disk and log in as `max`.

## Apply the fork

Open a terminal in the VM:

```sh
nix-shell -p git --run 'git clone https://github.com/max-miller1204/nixos-config.git ~/nixos-config'
cd ~/nixos-config
cp /etc/nixos/hardware-configuration.nix machines/hardware/vm-windows.nix
git add machines/hardware/vm-windows.nix
sudo nixos-rebuild build --flake .#vm-windows
sudo nixos-rebuild switch --flake .#vm-windows
sudo reboot
```

The generated hardware file preserves your disk UUIDs and driver settings.
The placeholder deliberately prevents rebuilding before that copy.
Your installer-created password remains valid because users are mutable.
Git uses your GitHub no-reply address; edit `users/max/home-manager.nix`
to change it. Neovim starts with a small working configuration; upstream's
private Chezmoi/LazyVim setup is not required.

For later updates, run `git pull`, then rebuild with the same `#vm-windows`
target. If you use the Makefile, run `make switch NIXNAME=vm-windows`.
Take a VMware snapshot before major changes. Desktop clipboard integration
requires VMware Guest Isolation copy/paste enabled; use an X11 session if
your Wayland session does not support it. Shared folders are optional and
are not mounted automatically by this profile.

Reference: https://nixos.org/download/
