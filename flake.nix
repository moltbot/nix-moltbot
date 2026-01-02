{
  description = "nix-clawdis: declarative Clawdis packaging for macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, home-manager }:
    let
      overlay = import ./nix/overlay.nix;
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      {
        packages = {
          clawdis-gateway = pkgs.clawdis-gateway;
          clawdis-app = pkgs.clawdis-app;
          clawdis = pkgs.clawdis;
          clawdis-tools-base = pkgs.clawdis-tools-base;
          clawdis-tools-extended = pkgs.clawdis-tools-extended;
          default = pkgs.clawdis;
        };

        apps = {
          clawdis = flake-utils.lib.mkApp { drv = pkgs.clawdis-gateway; };
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.git
            pkgs.nixfmt-rfc-style
            pkgs.nil
          ];
        };
      }
    ) // {
      overlays.default = overlay;
      homeManagerModules.clawdis = import ./nix/modules/home-manager/clawdis.nix;
      darwinModules.clawdis = import ./nix/modules/darwin/clawdis.nix;
    };
}
