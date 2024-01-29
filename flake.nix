{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    virsh-json = {
      url = "github:a-h/virshjson";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xc = {
      url = "github:joerdav/xc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    serve = {
      url = "github:a-h/serve";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixos-generators, virsh-json, xc, serve, ... }:
    let
      allHostnames = [
        "nix-host-a"
      ];
      forAllHostnames = f: nixpkgs.lib.genAttrs allHostnames (hostname: f {
        system = "x86_64-linux";
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        hostname = hostname;
      });
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        inherit system;
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      packages.vm = forAllHostnames ({ system, pkgs, hostname }: nixos-generators.nixosGenerate {
        system = system;
        specialArgs = {
          hostname = hostname;
        };
        modules = [
          # Pin nixpkgs to the flake input, so that the packages installed
          # come from the flake inputs.nixpkgs.url.
          ({ ... }: { nix.registry.nixpkgs.flake = nixpkgs; })
          # Define sl at the system level.
          ({ ... }: {
            environment.systemPackages = [
              pkgs.sl
            ];
          })
          # Apply the rest of the config.
          ./configuration.nix
        ];
        format = "qcow";
      });

      # `nix develop` provides a shell containing development tools.
      devShell = forAllSystems ({ system, pkgs }:
        pkgs.mkShell {
          buildInputs = [
            pkgs.jq
            pkgs.libvirt
            pkgs.virt-manager
            xc.packages.${system}.xc
            virsh-json.packages.${system}.default
            serve.packages.${system}.default
          ];
        });
    };
}
