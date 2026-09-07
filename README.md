# NixOS workstation

Declarative configuration for the `nixos` host and `hhyurdagul` user. NixOS owns hardware, security, containers, and the graphical session; Home Manager owns user packages, configuration, and graphical-session services.

## Repository layout

- `flake.nix`: inputs and the `nixos` system outputs.
- `hosts/nixos/`: system modules (hardware, boot, users, locale, Nix settings).
- `modules/`: shared NixOS modules (desktop session, Hyprland, containers).
- `home/hhyurdagul/`: Home Manager config — `default.nix` (programs, shell, XDG links), `packages.nix`, `services.nix`.
- `config/`: app dotfiles linked read-only by Home Manager (`darkman`, `helix`, `hypr`, `kitty`, `quickshell`, `swaylock`, `scripts`, `zsh`).

New files must be `git add`ed before rebuilding: flakes only see tracked files.

## Bootstrap and rebuild

From this checkout on an existing NixOS installation:

```sh
sudo nixos-rebuild switch --flake .#nixos
```

The first activation replaces legacy `$HOME/dotfiles/config/...` directory symlinks with Home Manager-managed files. Home Manager keeps a conflicting pre-existing file with an `.hm-backup` suffix.

Subsequent rebuilds:

```sh
sudo nixos-rebuild switch --flake .#nixos
```

Validate without activating:

```sh
nix flake check
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

## Updates and rollback

Update every locked input, inspect the lock-file diff, then build before switching:

```sh
nix flake update
nix flake check
sudo nixos-rebuild switch --flake .#nixos
```

Roll back the active system to the previous generation:

```sh
sudo nixos-rebuild switch --rollback
```

Older generations remain selectable from the boot menu. For a specific generation, run its `switch-to-configuration` program from `/nix/var/nix/profiles/system-<generation>-link/bin/`.

## Desktop session

`greetd` launches Hyprland through UWSM. Quickshell, hypridle, hyprpaper, darkman, wlsunset, NetworkManager's applet, and the clipboard watcher are user services tied to `graphical-session.target`.

Useful checks:

```sh
systemctl --user status graphical-session.target
systemctl --user status quickshell hypridle hyprpaper darkman wlsunset
journalctl --user -u quickshell -b
```

The generated Hyprpaper background follows the active light/dark theme. Replace the generated wallpaper derivations in `home/hhyurdagul/services.nix` when using personal images.

## Runtime theme controls

`Super+T` toggles light/dark mode without rebuilding. Runtime state lives under `$XDG_STATE_HOME/theme` (normally `~/.local/state/theme`), never in this Git checkout. Darkman uses the same `theme-switcher` command. The switch updates Quickshell, Kitty, GTK, Hyprland borders, and Hyprpaper.

Other session shortcuts:

- `Super+L`: lock
- `Super+Shift+I`: toggle idle locking
- `Super+Shift+N`: toggle night light

## Interactive shell

Zsh is managed declaratively by Home Manager with `ZDOTDIR=~/.config/zsh`, so a hand-written `~/.zshrc` is never read. Edit instead:

- `home/hhyurdagul/default.nix` (`programs.zsh`): options, history, plugins (`powerlevel10k`, `zsh-completions`), completion init.
- `config/zsh/early-init.zsh`: p10k instant prompt, must stay first in `.zshrc`.
- `config/zsh/init.zsh`: PATH, env, keybindings, tool inits (fzf, zoxide, uv), aliases.
- `config/zsh/p10k.zsh`: prompt theme, deployed as `~/.p10k.zsh`. Regenerate with `p10k configure`, then copy the result back here.

Reload the current shell after a switch with `sz`. Shell fragments are zsh: check syntax with `zsh -n`, not shellcheck.

## NVIDIA and containers

The internal Intel GPU drives the session. The RTX 4050 uses PRIME offload and fine-grained power management:

```sh
nvidia-offload <program>
nvidia-smi
```

Podman is the container backend. Docker-compatible commands and the user Docker socket are enabled; no Docker daemon is installed.

```sh
podman info
podman run --rm docker.io/library/hello-world
systemctl --user status podman.socket
```

## Secrets

`sops-nix` generates the host age key at `/var/lib/sops-nix/key.txt`; no secrets are currently declared. After the first switch, obtain the public recipient locally:

```sh
sudo age-keygen -y /var/lib/sops-nix/key.txt
```

Add that recipient to a repository `.sops.yaml`, encrypt values with `sops`, and declare only their paths/owners under `sops.secrets` in `modules/secrets.nix`. Never commit the private age key or decrypted values.

## Laptop policy

The host enables NVIDIA PRIME offload, firmware updates, Thunderbolt authorization, thermald, zram, and systemd-oomd. `ideapad-conservation-mode.service` enables Lenovo conservation mode at boot, limiting long-term charge to protect battery health. Disable that unit if a full charge is required for travel.
