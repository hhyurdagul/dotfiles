# NixOS workstation

Declarative configuration for the `nixos` host and `hhyurdagul` user. NixOS owns hardware, security, containers, and the graphical session; Home Manager owns user packages, configuration, and graphical-session services.

## Repository layout

- `flake.nix`: inputs and the `nixos` system outputs.
- `hosts/nixos/`: system modules (hardware, boot, users, locale, Nix settings).
- `modules/`: shared NixOS modules (desktop sessions, Hyprland, Niri, containers).
- `home/hhyurdagul/`: Home Manager config — `default.nix` (programs, shell, XDG links), `packages.nix`, `services.nix`.
- `config/`: app dotfiles linked read-only by Home Manager (`darkman`, `helix`, `hypr`, `niri`, `kitty`, `quickshell`, `scripts`, `zsh`).

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
nix flake check   # system build plus nixfmt, statix, deadnix, Ruff, and shell checks
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

## AI agents

CLIs and desktops come from [`numtide/llm-agents.nix`](https://github.com/numtide/llm-agents.nix), listed in `home/hhyurdagul/packages.nix`. That input does not follow this flake's nixpkgs, so installs use the prebuilt Numtide cache (`https://cache.numtide.com`). The substituter and its public key are set in `flake.nix` `nixConfig` and in `nix.settings`.

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

`greetd` defaults to **Niri**, launched through its native `niri-session`. Niri starts and stops `graphical-session.target` itself; it does not run inside UWSM. Quickshell, hypridle, darkman, wlsunset, Handy, NetworkManager's applet, and the clipboard watcher remain graphical-session services. X11 applications use Niri's automatically managed `xwayland-satellite`.

Hyprland remains installed as a selectable UWSM session in tuigreet's session menu. The original `modules/hyprland.nix` and `config/hypr/hyprland.lua` remain intact. The pre-migration state is commit `3cb76f6` in Git history. A local-only snapshot, **`backups/hyprland-before-niri.tar.gz`**, is ignored by Git (`.gitignore`) and may not exist in other checkouts; inspect it with `tar -tzf backups/hyprland-before-niri.tar.gz` and extract into a separate directory when comparing or restoring, rather than overwriting a live checkout. No system switch is performed by the migration.

The default login command intentionally does not remember the last selected session: a previously remembered Hyprland choice must not silently override the new Niri default. Select Hyprland explicitly when needed.

Useful checks:

```sh
systemctl --user status graphical-session.target
systemctl --user status quickshell hypridle hyprpaper darkman wlsunset
journalctl --user -u quickshell -b
```

Niri's solid background follows the active light/dark theme natively. Hyprpaper only runs in the Hyprland fallback. Replace the generated wallpaper derivations in `home/hhyurdagul/services.nix` for Hyprland images; configure a Niri-compatible wallpaper client separately if images are wanted in Niri.

LocalSend is enabled in `modules/desktop.nix`, including firewall access on TCP and UDP port 53317 for local-network transfers and discovery. After rebuilding and switching, launch **LocalSend** from the app launcher or run `localsend_app`. Both devices must be on the same local network.

## Runtime theme controls

`Super+Alt+T` toggles light/dark mode without rebuilding. Runtime state lives under `$XDG_STATE_HOME/theme` (normally `~/.local/state/theme`), never in this Git checkout. Darkman uses the same `theme-switcher` command. The switch updates Quickshell, GTK, and native Niri borders/shadows/background through a watched KDL include; Hyprland borders and Hyprpaper still update in the fallback session. Kitty and Electron apps (Obsidian, Claude, Paseo) follow the desktop `color-scheme` live; set Electron apps to their "system" theme.

Other session shortcuts:

- `Super+Alt+L`: lock
- `Super+Alt+I`: toggle idle management (dim, lock, screen-off, suspend)
- `Super+Alt+N`: toggle night light
- `Super+Volume up/down`: brightness on the focused screen, same steps as the brightness keys
- `Super+Mute`: toggle the focused external monitor between 0 and 100; ignored on the internal panel

### Niri shortcuts

`config/niri/config.kdl` is the source of truth. Home Manager embeds packaged helper paths into an immutable Nix-store file; `~/.config/niri/config.kdl` links to that generated file, not this checkout. Editing the source requires rebuilding and switching to activate it. Niri watches the installed config, so no logout is needed after activation.

This is a complete binding set, not an overlay on Niri's defaults. Overview,
column tabs, launcher, close, floating, width cycling, maximize, fullscreen, and
shortcut help use stock keys; other shortcuts retain the session's custom actions.
Default shortcuts omitted from `config.kdl` are not inherited.

| Shortcut | Niri action |
|---|---|
| `Super+Return`, `Super+T` | Kitty, Tern |
| `Super+B` | Zen |
| `Super+E`, `Super+D` | New Nautilus window (`GSK_RENDERER=ngl`), Fuzzel |
| `Super+O`, `Super+W`, `Super+Shift+Slash` (`Super+?`) | Overview, toggle column tabs, shortcut help |
| `Super+Q`, `Super+F`, `Super+V` | Close, maximize column, toggle floating |
| `Super+Shift+F` | Fullscreen |
| `Super+R` | Cycle column widths ⅓/½/⅔/full |
| `Super+[` / `Super+]` (US), `Super+ğ` / `Super+ü` (Turkish) | Stack into the left/right adjacent column or expel from a stack |
| `Super+Shift+M` | Lock and exit the native session |
| `Super+Alt+L/I/K/T/N/C` | Lock, toggle idle, next US/Turkish keyboard layout, theme, night light, laptop output |
| `Super+Tab` | Previous workspace |
| `Super+arrows` or `Super+H/J/K/L` | Focus left/down/up/right column/window, crossing monitors at edges |
| `Super+Shift+arrows` or `Super+Shift+H/J/K/L` | Move column horizontally or window vertically |
| `Super+1…0` | Named workspaces 1…10 (stable names, not per-output indices) |
| `Super+Shift+1…0` | Send window to named workspace 1…10 |
| `Super+Space` | Toggle Handy dictation; transcription history remains in Handy |
| Audio, microphone, brightness and media keys | Existing audio/brightness OSD and player controls, including while locked |
| `Super+Volume up/down`, `Super+Mute` | Focused-screen brightness and external-monitor brightness toggle |

Column tabs show one window at a time from a column, with vertical tab indicators
for its other windows. First group windows with `Super+[` / `Super+]` (US) or
`Super+ğ` / `Super+ü` (Turkish), then toggle tabs with `Super+W`; navigate them
with `Super+J/K` or `Super+Down/Up`.
Workspace 10 is an ordinary named workspace: `Super+0` focuses it and
`Super+Shift+0` sends a window there, with no special helper.

The `niri-display-policy` user service disables `eDP-1` when an HDMI output
becomes active and re-enables it when HDMI is disconnected or no HDMI output
remains active. It applies the same policy at session startup and waits for a
usable HDMI output before disabling the laptop panel. `Super+Alt+C` still
toggles the laptop panel manually; that choice persists until the HDMI
connection/activation state changes or the policy service restarts.

After output changes or workspace moves, the service orders named workspaces
numerically on each output without changing focus. With only one display active,
the order is always **1–10**, regardless of which display it is. When both
displays are enabled, workspaces retain their configured preferred outputs.
Niri's native trailing empty workspace remains; the custom `magic` workspace and
its `Super+X` / `Super+Shift+X` shortcuts have been removed.

Unmodified horizontal and vertical scrolling goes to applications. Do not add
bare wheel bindings: Niri 26.04 consumes both scroll axes whenever wheel bindings
match the held modifiers, even if only one axis is bound.
This version has no screen-zoom action or continuous wheel-panning action, so
`Super`+wheel is not bound to a substitute such as discrete column switching.
Native continuous horizontal panning uses `Super`+middle-button drag or a
three-finger horizontal touchpad swipe.


### Adaptations and non-equivalents

| Existing setting/shortcut | Niri behavior / limitation |
|---|---|
| Dwindle BSP layout, preserved splits | Native horizontally scrolling columns; no BSP/dwindle mode |
| Hyprland pseudotiling and split orientation | No BSP equivalent; `Super+R` cycles column widths and `Super+[`/`]` stack or expel windows |
| MX Master thumb button, with/without Shift | Next/previous workspace (`MouseForward`, Linux button 277) |
| Horizontal and vertical mouse wheels | Passed to apps without modifiers; no discrete column switching or screen-zoom substitute |
| `Super` + left/right drag | Native Niri move/resize; modifier behavior is compositor-defined |
| Three-finger horizontal workspace swipe | Native Niri horizontal column scrolling and vertical workspace switching; gesture axes differ |
| `Print` | Built-in area screenshot UI: select, Space to save, Escape to cancel |
| `Super+Print` (entire desktop) | Built-in focused-monitor screenshot; Niri has no equivalent all-monitor combined capture action |
| Added native defaults: `Ctrl+Print`, `Alt+Print` | Focused-monitor / focused-window screenshots; clipboard and default `Pictures/Screenshots` destination |
| Release-trigger screenshots and Handy dictation | Trigger on key press with repeat disabled; Niri 26.04 has no release-trigger bindings |
| Workspaces 1–5 laptop, 6–10 Lenovo external | Named workspaces with preferred outputs; migrated workspaces are sorted numerically per output, giving 1–10 on a single display. Niri also maintains dynamic empty workspaces |
| Laptop 2880×1800@120 scale 2; Lenovo 1920×1080@165 scale 1 | Lenovo left at (0, 0), laptop right at (1920, 0) in logical pixels; unknown outputs use Niri automatic mode/scale/placement |
| US/TR keyboard, Caps→Escape, natural touchpad scrolling, neutral mouse speed | Preserved; hover focuses any partially visible window and can scroll it into view, without a visibility/scroll-distance limit |
| 2 px gradient borders, 10 px rounding, full opacity, shadows, inner/outer gaps | Ported to Niri geometry; gap/shadow rendering is approximate |
| Hyprland blur size/passes/vibrancy | Native Niri blur approximation; algorithms and saturation/vibrancy differ |
| Hyprland animation tree and bespoke Bezier/spring curves | Native Niri animations; Hyprland leaf names, pop-in/fade styles and timing are not equivalent |
| Hyprland tearing disabled | No tearing requested; native compositor presentation behavior |
| Hyprland cursor zoom animation, logo/default wallpaper, inactive master/scrolling-layout knobs | Hyprland-only settings; not transferred as dead configuration |
| Empty-class/title XWayland drag workaround | No direct Niri window-rule equivalent; X11 is mediated by satellite |
| `hyprland-run` floating bottom-left rule | Ported where Niri's floating positioning supports it; placement uses Niri coordinates rather than `monitor_h` expressions |
| Quickshell Hyprland IPC/focus grabs | Shared Niri IPC backend and generic Wayland popup focus; Hyprland fallback remains supported |

Window rules set `draw-border-with-background false`: focus colors are drawn only
around window edges, not as a filled rectangle behind app content. This prevents
alpha-rendered clients such as Tern from inheriting the active border's green tint;
`opacity 1.0` alone does not override an app's own alpha channel.


Niri configuration and session references: [configuration](https://niri-wm.github.io/niri/Configuration%3A-Introduction.html), [native session management](https://niri-wm.github.io/niri/Getting-Started.html), [watched runtime includes](https://niri-wm.github.io/niri/Configuration%3A-Include.html).

## Interactive shell

Zsh is managed declaratively by Home Manager with `ZDOTDIR=~/.config/zsh`, so a hand-written `~/.zshrc` is never read. Edit instead:

- `home/hhyurdagul/default.nix` (`programs.zsh`): options, history, plugins (`powerlevel10k`, `zsh-completions`), completion init.
- `config/zsh/early-init.zsh`: p10k instant prompt, must stay first in `.zshrc`.
- `config/zsh/init.zsh`: PATH, env, keybindings, tool inits (fzf, zoxide, uv), aliases.
- `config/zsh/p10k.zsh`: prompt theme, deployed as `~/.p10k.zsh`. Regenerate with `p10k configure`, then copy the result back here.

Reload the current shell after a switch with `sz`. Shell fragments are zsh: check syntax with `zsh -n`, not shellcheck.

## Desktop tools

The clipboard icon immediately after the system tray opens searchable text and image history. Click or press Enter to copy an entry, Delete to remove one, and confirm before clearing everything. The current clipboard is not cleared with the history.

`imv` is the image viewer. File Roller opens zip, tar, gzip, 7z, and RAR archives (`unar` supplies RAR extraction). Satty annotates screenshots. OBS Studio records and streams.

## Disk health

`smartd` watches the NVMe continuously. An alert is stored even when you are logged out and shown after login. There is no scheduled system update or build. Firmware updates, TRIM, and Nix garbage collection were already enabled and are unchanged.

## NVIDIA and containers

The internal Intel GPU drives the session (`services.xserver.videoDrivers` lists `modesetting` first). The RTX 4050 uses PRIME offload and fine-grained runtime power management, with PCI power control pinned to `auto` by a udev rule, so it suspends (RTD3, video memory off) when idle:

```sh
nvidia-offload <program>
nvidia-smi
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
```

Podman is the container backend. Docker-compatible commands and the user Docker socket are enabled; no Docker daemon is installed.

```sh
podman info
podman run --rm docker.io/library/hello-world
systemctl --user status podman.socket
```

## Secrets

No NixOS-level secrets integration exists yet (no `sops-nix` input, no `modules/secrets.nix`). The `age` and `sops` CLIs are installed for manual encryption; wire `sops-nix` in `flake.nix` before documenting a key workflow here. Never commit private age keys or decrypted values.

## Laptop policy

The host enables NVIDIA PRIME offload, firmware updates, Thunderbolt authorization, thermald, zram, and systemd-oomd. `ideapad-conservation-mode.service` enables Lenovo conservation mode at boot, limiting long-term charge to protect battery health. Disable that unit if a full charge is required for travel. The installed machine is a Lenovo Yoga Pro 7 14IMH9, type 83E2, with a Core Ultra 7 155H. Its 16 GB LPDDR5X is soldered and has no RAM slots, so memory cannot be upgraded. The discrete-GPU configuration has one M.2 slot.
