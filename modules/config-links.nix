{ lib, pkgs, ... }:

let
  user = "hhyurdagul";
  homeDirectory = "/home/${user}";
  sourceRoot = "${homeDirectory}/dotfiles/config";
  targetRoot = "${homeDirectory}/.config";
in
{
  system.activationScripts.linkUserConfigs = {
    deps = [ "users" ];
    text = ''
      source_root=${lib.escapeShellArg sourceRoot}
      target_root=${lib.escapeShellArg targetRoot}

      if [ -d "$source_root" ]; then
        if [ ! -d "$target_root" ]; then
          ${pkgs.coreutils}/bin/install -d -m 0755 -o ${user} -g users "$target_root"
        fi

        for source in "$source_root"/*; do
          [ -d "$source" ] || continue

          name="$(${pkgs.coreutils}/bin/basename "$source")"
          target="$target_root/$name"

          if [ -L "$target" ]; then
            current="$(${pkgs.coreutils}/bin/readlink "$target")"
            if [ "$current" != "$source" ]; then
              echo "config-links: leaving existing symlink $target -> $current untouched" >&2
            fi
            continue
          fi

          if [ -e "$target" ]; then
            echo "config-links: leaving existing path $target untouched" >&2
            continue
          fi

          ${pkgs.coreutils}/bin/ln -s "$source" "$target"
          ${pkgs.coreutils}/bin/chown -h ${user}:users "$target"
        done

        # Link Darkman hook directories in ~/.local/share/
        local_share="${homeDirectory}/.local/share"
        ${pkgs.coreutils}/bin/install -d -m 0755 -o ${user} -g users "$local_share"
        for mode in light-mode.d dark-mode.d; do
          hook_source="$source_root/darkman/$mode"
          hook_target="$local_share/$mode"
          if [ -d "$hook_source" ]; then
            if [ -L "$hook_target" ]; then
              current="$(${pkgs.coreutils}/bin/readlink "$hook_target")"
              [ "$current" = "$hook_source" ] || ${pkgs.coreutils}/bin/ln -sfn "$hook_source" "$hook_target"
            elif [ ! -e "$hook_target" ]; then
              ${pkgs.coreutils}/bin/ln -s "$hook_source" "$hook_target"
            fi
            ${pkgs.coreutils}/bin/chown -h ${user}:users "$hook_target" 2>/dev/null || true
          fi
        done
      fi
    '';
  };
}
