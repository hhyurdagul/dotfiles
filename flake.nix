{
  description = "Hasan's NixOS workstation";

  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # For packages that move faster than the stable release (e.g. zed-editor).
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Development Hyprland with its matching portal and NixOS module.
    hyprland.url = "github:hyprwm/Hyprland";

    # Do not follow nixpkgs. Packages are cached against this flake's own pin.
    llm-agents.url = "github:numtide/llm-agents.nix";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      username = "hhyurdagul";
      pkgs = nixpkgs.legacyPackages.${system};

      lintSource = pkgs.lib.fileset.toSource {
        root = ./.;
        fileset = pkgs.lib.fileset.fileFilter (
          file:
          file.hasExt "nix"
          || file.hasExt "py"
          || file.hasExt "sh"
          || file.hasExt "zsh"
          || file.name == ".envrc"
        ) ./.;
      };
      lintCheck =
        name: tools: command:
        pkgs.runCommand "dotfiles-${name}" { nativeBuildInputs = tools; } ''
          set -euo pipefail
          cd ${lintSource}
          ${command}
          touch "$out"
        '';

      nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username; };

        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/nixos

          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              extraSpecialArgs = { inherit inputs username; };
              users.${username} = import ./home/${username};
            };
          }
        ];
      };
    in
    {
      formatter.${system} = pkgs.nixfmt;

      nixosConfigurations.nixos = nixos;

      checks.${system} = {
        nixos = nixos.config.system.build.toplevel;
        nixfmt = lintCheck "nixfmt" [ pkgs.nixfmt pkgs.findutils ] ''
          find . -type f -name '*.nix' -print0 | xargs -0 -r nixfmt --check
        '';
        statix = lintCheck "statix" [ pkgs.statix ] "statix check .";
        deadnix = lintCheck "deadnix" [ pkgs.deadnix ] "deadnix --fail .";
        ruff = lintCheck "ruff" [ pkgs.python3Packages.ruff ] "ruff check --no-cache .";
        shell = lintCheck "shell" [ pkgs.shellcheck pkgs.zsh pkgs.findutils ] ''
          while IFS= read -r -d "" script; do
            bash -n "$script"
            if [[ "$script" == ./config/scripts/theme-switcher.sh ]]; then
              # Home Manager supplies these before including this fragment.
              {
                printf 'CURSOR_THEME=Adwaita\nCURSOR_SIZE=24\n'
                cat "$script"
              } | shellcheck --shell=bash -
            else
              shellcheck --shell=bash "$script"
            fi
          done < <(find . -type f \( -name '*.sh' -o -name .envrc \) -print0)
          while IFS= read -r -d "" script; do
            zsh -n "$script"
          done < <(find ./config/zsh -type f -name '*.zsh' -print0)
        '';
      };

      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          deadnix
          nixfmt
          python3Packages.ruff
          shellcheck
          shfmt
          statix
          zsh
        ];
      };

    };
}
