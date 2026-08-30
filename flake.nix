{
  description = "My NixOS flake configuration";

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

    # Development Hyprland with its matching portal and NixOS module.
    hyprland.url = "github:hyprwm/Hyprland";

    # Helium Browser
    helium.url = "github:oxcl/nix-flake-helium-browser";
    helium.inputs.nixpkgs.follows = "nixpkgs";

    # AI Flakes
    antigravity.url = "github:jacopone/antigravity-nix";
    antigravity.inputs.nixpkgs.follows = "nixpkgs";

    codex.url = "github:sadjow/codex-cli-nix";
    codex.inputs.nixpkgs.follows = "nixpkgs";

    omp.url = "github:can1357/oh-my-pi";
    omp.inputs.nixpkgs.follows = "nixpkgs";

    hermes.url = "github:NousResearch/hermes-agent";
    hermes.inputs.nixpkgs.follows = "nixpkgs";

    herdr.url = "github:herdrdev/herdr";
    herdr.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      system = "x86_64-linux";
      overlay = final: prev: {
        helium = inputs.helium.packages.${system}.default;
        antigravity = inputs.antigravity.packages.${system}.google-antigravity-cli;
        codex = inputs.codex.packages.${system}.default;
        omp = inputs.omp.packages.${system}.default;
        hermes = inputs.hermes.packages.${system}.default;
        herdr = inputs.herdr.packages.${system}.default;
      };
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };

        modules = [
          {
            nixpkgs.overlays = [ overlay ];
            nix.settings = {
              extra-substituters = [
                "https://hyprland.cachix.org"
                "https://nix-community.cachix.org"
              ];
              extra-trusted-public-keys = [
                "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
              trusted-users = [
                "root"
                "@wheel"
              ];
            };
          }

          # Host Configuration (Hardware, Boot, Locale, Users, Nix Settings)
          ./hosts/nixos

          # Desktop & Compositors
          ./modules/desktop-shared.nix
          ./modules/hyprland.nix
          ./modules/niri.nix

          # Applications & Tools
          ./modules/browsers.nix
          ./modules/ai.nix
          ./modules/cli.nix

          # Dotfiles Activation
          ./modules/config-links.nix
        ];
      };
    };
}
