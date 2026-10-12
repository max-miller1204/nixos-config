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
nix build --no-link "$target.config.system.build.toplevel"
nix shell --inputs-from "$auditDir" nixpkgs#i3 nixpkgs#rofi nixpkgs#xvfb-run \
  -c xvfb-run -a bash -c '
    set -euo pipefail
    i3 -C -c "$1/users/maxm/i3"
    rofi -no-config -theme "$1/users/maxm/rofi" -dump-theme >/dev/null
  ' bash "$auditDir"
