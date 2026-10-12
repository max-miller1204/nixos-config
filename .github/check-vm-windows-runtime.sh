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
ompPath=$(buildAttr programs.oh-my-posh.package)
"$ompPath/bin/oh-my-posh" init nu --print --config "$auditDir/users/mitchellh/omp.json" >"$auditDir/omp-init.nu"
# The CMD_DURATION_MS type error appears only after a real REPL command.
python3 - "$nuPath/bin/nu" "$auditDir/omp-init.nu" "$auditDir/omp-repl.log" <<'PY'
import os, pty, re, select, signal, sys, tempfile, time
nu, init, log = sys.argv[1:]
pid, fd = pty.fork()
if pid == 0:
    os.environ.update(HOME=tempfile.mkdtemp(prefix="nu-prompt-home-"), TERM="xterm-256color")
    os.execl(nu, nu, "--config", init)
output = bytearray()
sent = False
status = None
deadline = time.monotonic() + 30
while time.monotonic() < deadline:
    if select.select([fd], [], [], 0.2)[0]:
        try:
            chunk = os.read(fd, 65536)
        except OSError:
            break
        if not chunk:
            break
        output.extend(chunk)
        if not sent:
            os.write(fd, b'sleep 100ms\rprint "OMP_PROMPT_CHECK"\rexit\r')
            sent = True
    ended, result = os.waitpid(pid, os.WNOHANG)
    if ended:
        status = result
        break
if status is None:
    ended, status = os.waitpid(pid, os.WNOHANG)
    if not ended:
        os.kill(pid, signal.SIGKILL)
        _, status = os.waitpid(pid, 0)
clean = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", output.decode(errors="replace"))
with open(log, "w") as stream:
    stream.write(clean)
print(clean)
if os.waitstatus_to_exitcode(status) != 0 or not re.search(r"[\r\n]OMP_PROMPT_CHECK[\r\n]", clean):
    raise SystemExit("Nushell prompt REPL check did not complete")
if re.search(r"nu::|Error:|expected int|Type mismatch", clean):
    raise SystemExit("Nushell prompt REPL check reported an error")
PY
if [ "${PROMPT_ONLY:-false}" = "true" ]; then exit 0; fi
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
