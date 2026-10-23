# AGENTS.md

Guide for AI agents working in this repo. `README.md` covers how a person operates
the machine. This file covers the rules and how to make changes without
rediscovering the layout. Quickshell has its own guide in `config/quickshell/AGENTS.md`.

## Hard rules

- **Declarative only.** Every package, service, file in `$HOME`, and setting goes
  through this flake. Never `nix profile install`, `nix-env -i`, `npm -g`,
  `pip install`, `curl | sh`, AppImages, or hand-written files in `~/.config`.
  If something cannot be packaged (auth-gated download, closed beta), say so and
  stop. Do not fall back to an imperative install.
- **No commits.** Leave changes in the working tree. Do not commit, amend, or push
  unless asked. Staging new files is fine and required (see below).
- **Build, don't switch.** Verify with a build. The user runs
  `sudo nixos-rebuild switch --flake .#nixos` unless they ask you to.
- **Edit sources, not targets.** Files under `~/.config`, `~/.p10k.zsh`, etc. are
  read-only Home Manager symlinks into the store. Change the file in this repo.
- **No secrets** in Nix values or git. There is no sops-nix integration yet.

## The machine

One host (`nixos`, a Lenovo laptop: Intel iGPU drives the session, RTX 4050 via
PRIME offload) and one user (`hhyurdagul`). Turkish keyboard and formats,
English UI, Europe/Istanbul. NixOS 26.05 stable, with Home Manager as a NixOS
module (`useGlobalPkgs`, `useUserPackages`, so user packages land in
`/etc/profiles/per-user/hhyurdagul`).

Session: greetd/tuigreet → `niri-session` → Niri (config in `config/niri/config.kdl`).
Hyprland stays as a selectable UWSM fallback (git build from the `hyprland` input,
**Lua config** in `config/hypr/hyprland.lua`). Quickshell is the bar,
notifications, and OSD. Catppuccin light/dark switched at runtime by darkman +
`theme-switcher`. Kitty, Helix (`EDITOR=hx`), zsh + powerlevel10k, Zen as the
default browser, Podman with Docker compatibility. Many AI agent CLIs and desktop
apps come from numtide's `llm-agents.nix`.

## Where things go

| Change | Place |
| --- | --- |
| Hardware, boot, users, locale, Nix settings | `hosts/nixos/` |
| System services: desktop, Niri/greetd, Hyprland, containers | `modules/*.nix` |
| User package | `home/hhyurdagul/packages.nix` (see sources below) |
| User service | `home/hhyurdagul/services.nix`, extending `graphicalService` (`graphical-service.nix`) with `lib.recursiveUpdate` |
| Dotfile | `config/<app>/…`, linked from `xdg.configFile` in `home/hhyurdagul/default.nix` |
| Helper script | `config/scripts/<name>.sh`, packaged in `services.nix` with `writeShellApplication` + explicit `runtimeInputs` |
| Default apps / MIME | `xdg.mimeApps` in `home/hhyurdagul/default.nix` |
| Shell options, plugins | `programs.zsh` in `default.nix`; aliases and env in `config/zsh/init.zsh` |

Niri and Hyprland binds call helpers by bare name. `services.nix` rewrites
`niri/config.kdl` and `hypr/hyprland.lua` with `builtins.replaceStrings` to
absolute store paths. A new helper called from a bind needs an entry there too.

## Package sources

`packages.nix` has separate lists. Put a package in the one that matches its source:

- `pkgs.*`: nixpkgs stable, the default choice.
- `agents.*`: `inputs.llm-agents.packages.${system}`, for AI tools. This input
  intentionally does **not** follow our nixpkgs, so it hits `cache.numtide.com`.
  Attribute names don't always match binary names (`paperclip` → `paperclipai`),
  and many apps have a `-desktop` variant. List what exists first:
  ```sh
  nix eval --raw --impure --expr 'let f = builtins.getFlake (toString ./.); in builtins.concatStringsSep "\n" (builtins.attrNames f.inputs.llm-agents.packages.x86_64-linux)'
  ```
- `unstable.*`: `nixpkgs-unstable`, only for fast-moving apps (for example `zed-editor`).
- Other flake inputs (zen-browser) and locally wrapped packages go in the trailing list.

Unfree packages from `pkgs` must be named in `allowUnfreePredicate` in
`hosts/nixos/default.nix`. Inputs that bring their own nixpkgs instance
(llm-agents) don't need it.

New flake inputs should `follows = "nixpkgs"` unless they ship a binary cache
built against their own pin (llm-agents, hyprland). In that case add the cache
to **both** `nixConfig` in `flake.nix` and `nix.settings` in `hosts/nixos/default.nix`.

## Known traps

- **Leaked `LD_LIBRARY_PATH`.** Prebuilt binaries wrapped with
  `makeWrapper --prefix LD_LIBRARY_PATH` pass it to every child process. With
  libraries from a different nixpkgs (glibc mismatch), children such as
  `xdg-open` → browser die silently. Symptom: "the button does nothing". Fix: `overrideAttrs` a
  `postInstall` that re-runs `makeWrapper` without the variable (the binaries
  usually carry a full RPATH already).
- **Incomplete upstream packages.** If an llm-agents app is missing a piece it
  downloads at build time upstream, package that piece here and inject it with
  `symlinkJoin` + `wrapProgram`, as `aionui`/`aioncore` in `packages.nix` do. Don't
  patch the input.
- **Untracked files are invisible** to the flake. `git add` new files before building.
- **Read-only store.** Apps that update themselves (or write next to their binary)
  can't. Update them by bumping the flake input or version/hash.
- `home.activation` scripts are only for one-shot migrations. Don't use them to
  install things.

## Verify every change

```sh
nix build --no-link .#nixosConfigurations.nixos.config.system.build.toplevel   # main check, no sudo
nix fmt -- --check <files>                                                    # nixfmt
nix develop -c statix check . && nix develop -c deadnix .                     # lint
zsh -n config/zsh/init.zsh                                                    # zsh fragments (not shellcheck)
```

Scripts packaged with `writeShellApplication` are shellchecked at build time.
To see what Home Manager will put on `PATH`:

```sh
ls "$(nix eval --raw .#nixosConfigurations.nixos.config.home-manager.users.hhyurdagul.home.path)/bin"
```

## Environment notes for agents

- The login shell is zsh. Quote words that start with `=` (`echo '==='`), because
  zsh expands `=cmd`.
- `python3` (from `packages.nix`), `uv` and `jq` are on `PATH`.
- Runtime state (theme mode, etc.) lives in `~/.local/state`, never in this repo.
- Logs: `journalctl --user -u <service>`. App logs usually sit under
  `~/.local/share/<app>/`.
- `kernel.yama.ptrace_scope=1`: `strace` only works on processes you launch.
