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
              instances.default = {
                enable = true;
                providers.telegram = {
                  enable = true;
                  # REPLACE: path to your bot token file
                  botTokenFile = "<tokenPath>";
                  # REPLACE: your Telegram user ID (get from @userinfobot)
                  allowFrom = [ <allowFrom> ];
                  # Group defaults (required in Nix mode):
                  groups = {
                    "*" = { requireMention = true; };
                  };
                };
                providers.anthropic = {
                  # REPLACE: path to your Anthropic API key file
                  apiKeyFile = "<anthropicKeyPath>";
                };

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
