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
nuPath=$(buildAttr programs.nushell.package)
if [ "${PROMPT_ONLY:-false}" != "true" ]; then
  ghosttyPath=$(buildHomePackage 'p: (p.pname or "") == "ghostty"')
  fishPath=$(buildAttr programs.fish.package)
  "$ghosttyPath/bin/ghostty" +validate-config --config-file="$auditDir/users/maxm/ghostty.linux"
  "$fishPath/bin/fish" --no-execute "$auditDir/users/maxm/config.fish"
  NU_CONFIG_CHECK="$auditDir/users/maxm/config.nu" "$nuPath/bin/nu" --no-config-file \
    -c 'if not (nu-check --debug $env.NU_CONFIG_CHECK) { exit 1 }'
fi
ompPath=$(buildAttr programs.oh-my-posh.package)
atuinPath=$(buildAttr programs.atuin.package)
direnvPath=$(buildAttr programs.direnv-instant.finalPackage)
direnvCommand=$(buildAttr programs.direnv.package)
nuConfig=$(buildAttr 'home.file."/home/maxm/.config/nushell/config.nu".source')
ompConfig=$(buildAttr 'xdg.configFile."oh-my-posh/config.json".source')
export PATH="$nuPath/bin:$atuinPath/bin:$ompPath/bin:$direnvPath/bin:$direnvCommand/bin:$PATH"
# The CMD_DURATION_MS type error appears only after a real REPL command.
python3 - "$nuPath/bin/nu" "$nuConfig" "$ompConfig" "$auditDir/omp-repl.log" <<'PY'
import fcntl, json, os, pty, re, select, shutil, signal, struct, sys, tempfile, termios, time
nu, init, omp_config, log = sys.argv[1:]
pid, fd = pty.fork()
if pid == 0:
    prompt_home = tempfile.mkdtemp(prefix="nu-prompt-home-")
    os.environ.update(HOME=prompt_home, TERM="xterm-256color",
                      XDG_CONFIG_HOME=prompt_home + "/.config",
                      XDG_DATA_HOME=prompt_home + "/.local/share",
                      XDG_STATE_HOME=prompt_home + "/.local/state",
                      XDG_CACHE_HOME=prompt_home + "/.cache")
    os.makedirs(prompt_home + "/.config/oh-my-posh")
    shutil.copyfile(omp_config, prompt_home + "/.config/oh-my-posh/config.json")
    with open(init) as stream:
        config = stream.read().replace("/home/maxm", prompt_home)
    init_copy = prompt_home + "/config.nu"
    with open(init_copy, "w") as stream:
        stream.write(config)
    # User autoload runs after Oh My Posh's vendor autoload sets the indicator.
    os.makedirs(prompt_home + "/.config/nushell/autoload")
    with open(prompt_home + "/.config/nushell/autoload/zz-test.nu", "w") as stream:
        stream.write('$env.PROMPT_INDICATOR = "NU_TEST> "\n')
    os.chdir(prompt_home)
    os.execl(nu, nu, "--env-config", "/dev/null", "--config", init_copy)
fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 120, 0, 0))
output = bytearray()
sent = False
status = None
position_replies = 0
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
        queries = bytes(output).count(b"\x1b[6n")
        if queries > position_replies:
            os.write(fd, b"\x1b[1;1R" * (queries - position_replies))
            position_replies = queries
        if not sent and b"NU_TEST> " in output:
            os.write(fd, b'sleep 100ms\rprint "OMP_PROMPT_CHECK"\rprint ($env.config.keybindings | where {|b| $b.name == "atuin" or $b.name == "atuin_up_arrow"} | get name | to json --raw)\rexit\r')
            sent = True
    ended, result = os.waitpid(pid, os.WNOHANG)
    if ended:
        status = result
        break
if status is None:
    for _ in range(20):
        ended, status = os.waitpid(pid, os.WNOHANG)
        if ended:
            break
        time.sleep(0.05)
    if not ended:
        os.kill(pid, signal.SIGKILL)
        _, status = os.waitpid(pid, 0)
clean = re.sub(r"\x1b\].*?(?:\x07|\x1b\\)", "", output.decode(errors="replace"), flags=re.S)
clean = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]|\x1b[78]", "", clean)
with open(log, "w") as stream:
    stream.write(clean)
print(clean)
if os.waitstatus_to_exitcode(status) != 0 or not re.search(r"[\r\n]OMP_PROMPT_CHECK[\r\n]", clean):
    raise SystemExit("Nushell prompt REPL check did not complete")
if re.search(r"nu::|Error:|expected int|Type mismatch", clean):
    raise SystemExit("Nushell prompt REPL check reported an error")
bindings = re.findall(r'^\["atuin".*\]\r?$', clean, flags=re.M)
if not bindings or sorted(json.loads(bindings[-1])) != ["atuin", "atuin_up_arrow"]:
    raise SystemExit("Atuin Ctrl+R and Up-arrow bindings were not both retained")
PY
if [ "${PROMPT_ONLY:-false}" = "true" ]; then exit 0; fi
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
