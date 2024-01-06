{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-generators, ... }: {
    packages.aarch64-linux = {
      iso = nixos-generators.nixosGenerate {
        system = "aarch64-linux";
        modules = [
          ./configuration.nix
        ];
        format = "iso";
      };
    };
  };
}
