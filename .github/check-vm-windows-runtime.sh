#!/usr/bin/env bash
set -euo pipefail

# Exercise the real selected packages and generated editor config independently
# of the longer full-system/Jujutsu build.
auditDir=$(mktemp -d -t vm-windows-runtime.XXXXXXXX)
git archive HEAD | tar -x -C "$auditDir"
cp "$auditDir/.github/fixtures/vm-windows-hardware.nix" "$auditDir/machines/hardware/vm-windows.nix"
target="$auditDir#nixosConfigurations.vm-windows.config.home-manager.users.maxm"
buildAttr() { nix build --no-link --print-out-paths "$target.$1"; }
buildHomePackage() {
  nix build --no-link --print-out-paths --impure --expr \
    "let ps = (builtins.getFlake \"$auditDir\").nixosConfigurations.vm-windows.config.home-manager.users.maxm.home.packages; in builtins.head (builtins.filter ($1) ps)"
}
ghosttyPath=$(buildHomePackage 'p: (p.pname or "") == "ghostty"')
fishPath=$(buildAttr programs.fish.package)
nuPath=$(buildAttr programs.nushell.package)
"$ghosttyPath/bin/ghostty" +validate-config --config-file="$auditDir/users/maxm/ghostty.linux"
"$fishPath/bin/fish" --no-execute "$auditDir/users/maxm/config.fish"
NU_CONFIG_CHECK="$auditDir/users/maxm/config.nu" "$nuPath/bin/nu" --no-config-file \
  -c 'if not (nu-check --debug $env.NU_CONFIG_CHECK) { exit 1 }'
direnvPath=$(buildAttr programs.direnv-instant.finalPackage)
"$direnvPath/bin/direnv-instant" hook fish >"$auditDir/direnv-hook.fish"
"$fishPath/bin/fish" --no-execute "$auditDir/direnv-hook.fish"

nvimPath=$(buildAttr programs.neovim.finalPackage)
initPath=$(buildAttr 'xdg.configFile."nvim/init.lua".source')
luaPath=$(nix eval --raw "$target.xdg.configFile.\"nvim/lua\".source")
clangPath=$(buildHomePackage 'p: builtins.match "clang-wrapper-.*" p.name != null')
editorHome=$(mktemp -d -t vm-windows-editor-runtime.XXXXXXXX)
mkdir -p "$editorHome/.config/nvim"
cp "$initPath" "$editorHome/.config/nvim/init.lua"
cp -rL "$luaPath" "$editorHome/.config/nvim/lua"
chmod -R u+w "$editorHome/.config"
export HOME="$editorHome"
export XDG_CONFIG_HOME="$editorHome/.config"
export XDG_DATA_HOME="$editorHome/.local/share"
export XDG_STATE_HOME="$editorHome/.local/state"
export XDG_CACHE_HOME="$editorHome/.cache"
export PATH="$clangPath/bin:$PATH"
if ! nix shell --inputs-from "$auditDir" nixpkgs#git nixpkgs#curl nixpkgs#gnumake \
  nixpkgs#unzip nixpkgs#wget nixpkgs#go -c \
  timeout 300 "$nvimPath/bin/nvim" --headless '+Lazy! sync' '+qa' >"$editorHome/neovim.log" 2>&1; then
  cat "$editorHome/neovim.log"
  exit 1
fi
cat "$editorHome/neovim.log"
if grep -E 'Error detected while processing|Error in command line:|E[0-9]{3}:|Failed to (clone|run|install)|Unmet requirements' "$editorHome/neovim.log"; then
  exit 1
fi
