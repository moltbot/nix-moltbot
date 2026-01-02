self: super:
let
  sourceInfo = import ./sources/clawdis-source.nix;
  clawdisGateway = super.callPackage ./packages/clawdis-gateway.nix {
    inherit sourceInfo;
  };
  clawdisApp = super.callPackage ./packages/clawdis-app.nix { };
  toolSets = import ./tools/extended.nix { pkgs = super; };
  clawdisBundle = super.callPackage ./packages/clawdis-batteries.nix {
    clawdis-gateway = clawdisGateway;
    clawdis-app = clawdisApp;
    extendedTools = toolSets.extended;
  };
in {
  clawdis-gateway = clawdisGateway;
  clawdis-app = clawdisApp;
  clawdis = clawdisBundle;
  clawdis-tools-base = toolSets.base;
  clawdis-tools-extended = toolSets.extended;
}
