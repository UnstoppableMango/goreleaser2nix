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

    gomod2nix = {
      url = "github:nix-community/gomod2nix";
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
        { config, pkgs, ... }:
        let
          pkgs' = (pkgs.extend inputs.gomod2nix.overlays.default).extend inputs.self.overlays.default;
        in
        {
          # buildGoModule-backed example (default)
          packages.buildgomodule = pkgs'.mkGoreleaserBuild {
            pname = "example";
            version = "0.0.0";
            src = ./examples/buildgomodule;
            vendorHash = null;
          };

          # gomod2nix-backed example (opt-in)
          packages.gomod2nix = pkgs'.mkGoreleaserBuild {
            pname = "example";
            version = "0.0.0";
            src = ./examples/gomod2nix;
            useGomod2nix = true;
            modules = ./examples/gomod2nix/gomod2nix.toml;
          };

          packages.default = config.packages.buildgomodule;

          checks = config.packages;

          devShells.default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              gnumake
              goreleaser
              nixfmt
              pkgs'.gomod2nix
            ];
          };

          treefmt.programs = {
            nixfmt.enable = true;
          };
        };
    };
}
