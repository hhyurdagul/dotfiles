{
  description = "My NixOs Flake Setup";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
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
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        ./ai.nix
        {
          environment.systemPackages = [
            inputs.helium.packages.x86_64-linux.default
          ];
        }
      ];
    };
  };
}
