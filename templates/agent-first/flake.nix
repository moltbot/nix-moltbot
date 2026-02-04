{
  description = "Openclaw local";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-openclaw.url = "github:openclaw/nix-openclaw";
  };

  outputs = { self, nixpkgs, home-manager, nix-openclaw }:
    let
      # REPLACE: aarch64-darwin (Apple Silicon), x86_64-darwin (Intel), or x86_64-linux
      system = "<system>";
      pkgs = import nixpkgs { inherit system; overlays = [ nix-openclaw.overlays.default ]; };
    in {
      # REPLACE: <user> with your username (run `whoami`)
      homeConfigurations."<user>" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nix-openclaw.homeManagerModules.openclaw
          {
            # Required for Home Manager standalone
            home.username = "<user>";
            # REPLACE: /Users/<user> on macOS or /home/<user> on Linux
            home.homeDirectory = "<homeDir>";
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;

            programs.openclaw = {
              # REPLACE: path to your managed documents directory
              documents = ./documents;

              # Matrix is enabled by default (replaces Telegram)
              matrix = {
                enable = true;
                # REPLACE: Your Matrix homeserver URL (default uses https://matrix.aboutco.ai/)
                homeserverUrl = "https://matrix.aboutco.ai/";
                # REPLACE: Your Matrix bot user ID (e.g., @mybot:aboutco.ai)
                userId = "<matrixUserId>";
                # REPLACE: Path to file containing Matrix access token
                # Get token via: curl -X POST https://matrix.aboutco.ai/_matrix/client/v3/login \
                #   -H 'Content-Type: application/json' \
                #   -d '{"type":"m.login.password","identifier":{"type":"m.id.user","user":"USERNAME"},"password":"PASSWORD"}'
                accessTokenFile = "<accessTokenPath>";
              };

              instances.default = {
                enable = true;
                # Note: The @openclaw/matrix plugin is loaded automatically when Matrix is enabled
                plugins = [
                  # Example plugin without config:
                  { source = "github:acme/hello-world"; }
                ];
              };
            };
          }
        ];
      };
    };
}
