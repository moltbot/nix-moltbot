{
  description = "Hello-world Openclaw plugin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        packages.default = pkgs.buildGoModule {
          pname = "hello-world";
          version = "0.1.0";
          src = ./.;
          vendorHash = null;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };

        openclawPlugin = {
          name = "hello-world";
          skills = [ ./skills/hello-world ];
          packages = [ self.packages.${system}.default ];
          needs = {
            stateDirs = [];
            requiredEnv = [];
          };
        };
      }
    );
}
