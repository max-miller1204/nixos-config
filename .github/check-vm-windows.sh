#!/usr/bin/env bash
set -euo pipefail

# Use a disposable copy so the deliberate installation guard stays intact.
# CI validates the committed profile without inventing the user's disk UUIDs.
auditDir=$(mktemp -d -t vm-windows-check.XXXXXXXX)
git archive HEAD | tar -x -C "$auditDir"
cp "$auditDir/.github/fixtures/vm-windows-hardware.nix" \
  "$auditDir/machines/hardware/vm-windows.nix"
target="$auditDir#nixosConfigurations.vm-windows"

nix eval --raw "$target.config.system.build.toplevel.drvPath"
systemPath=$(nix build --no-link --print-out-paths "$target.config.system.build.toplevel")
homePath=$(nix build --no-link --print-out-paths "$target.config.home-manager.users.maxm.home.path")
homeGeneration=$(nix build --no-link --print-out-paths "$target.config.home-manager.users.maxm.home.activationPackage")
nix shell --inputs-from "$auditDir" nixpkgs#i3 nixpkgs#rofi nixpkgs#xvfb-run \
  -c xvfb-run -a bash -c '
    set -euo pipefail
    i3 -C -c "$1/users/maxm/i3"
    rofi -no-config -theme "$1/users/maxm/rofi" -dump-theme >/dev/null
    "$2/sw/bin/xrandr-auto"
  ' bash "$auditDir" "$systemPath"
"$homePath/bin/ghostty" +validate-config --config-file="$auditDir/users/maxm/ghostty.linux"
"$homePath/bin/fish" --no-execute "$auditDir/users/maxm/config.fish"
NU_CONFIG_CHECK="$auditDir/users/maxm/config.nu" "$homePath/bin/nu" --no-config-file \
  -c 'if not (nu-check --debug $env.NU_CONFIG_CHECK) { exit 1 }'

# Launch the actual Home Manager Neovim wrapper with its generated config.
# Use isolated writable directories for the LazyVim starter's plugin downloads.
editorHome=$(mktemp -d -t vm-windows-editor.XXXXXXXX)
cp -rL "$homeGeneration/home-files/.config" "$editorHome/.config"
chmod -R u+w "$editorHome/.config"
export HOME="$editorHome"
export XDG_CONFIG_HOME="$editorHome/.config"
export XDG_DATA_HOME="$editorHome/.local/share"
export XDG_STATE_HOME="$editorHome/.local/state"
export XDG_CACHE_HOME="$editorHome/.cache"
export PATH="$homePath/bin:$systemPath/sw/bin:$PATH"
if ! timeout 300 "$homePath/bin/nvim" --headless '+Lazy! sync' '+qa' >"$editorHome/neovim.log" 2>&1; then
  cat "$editorHome/neovim.log"
  exit 1
fi
cat "$editorHome/neovim.log"
if grep -E 'Error detected while processing|E[0-9]{3}:|Failed to clone lazy.nvim' "$editorHome/neovim.log"; then
  exit 1
fi
