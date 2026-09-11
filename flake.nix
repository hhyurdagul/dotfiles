{
  description = "Hasan's NixOS workstation";

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Development Hyprland with its matching portal and NixOS module.
    hyprland.url = "github:hyprwm/Hyprland";

    antigravity = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    omp = {
      url = "github:can1357/oh-my-pi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:herdrdev/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chatgpt-nix = {
      url = "github:hhyurdagul/chatgpt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

      checks.${system}.nixos = nixos.config.system.build.toplevel;

      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          deadnix
          nixfmt
          python3Packages.ruff
          shellcheck
          shfmt
          statix
        ];
      };

    };
}
