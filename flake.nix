{
  description = "My NixOS flake configuration";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";

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
    hermes.url = "github:NousResearch/hermes-agent";
    herdr = {
      url = "github:herdrdev/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      system = "x86_64-linux";
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./config-links.nix
          ./desktop.nix
          ./ai.nix
        ];
      };
    };
}
