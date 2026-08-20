{
  description = "A Nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/triplet";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [ inputs.treefmt-nix.flakeModule ];

      flake.overlays.default = final: prev: {
        mkGoreleaserBuild = final.callPackage ./nix/goreleaser-build.nix { };
      };

      perSystem =
        { pkgs, ... }:
        let
          pkgs' = pkgs.extend inputs.self.overlays.default;
        in
        {
          packages.default = pkgs'.mkGoreleaserBuild {
            pname = "example";
            version = "0.0.0";
            src = ./example;
            vendorHash = null;
          };

          devShells.default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              gnumake
              goreleaser
              nixfmt
            ];
          };

          treefmt.programs = {
            nixfmt.enable = true;
          };
        };
    };
}
