{ config, lib, ... }:

{
  config = lib.mkIf (config ? home-manager) {
    home-manager.sharedModules = [ ../home-manager/openclaw.nix ];
  };
}
