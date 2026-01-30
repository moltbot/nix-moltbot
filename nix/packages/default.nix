{ pkgs
, sourceInfo ? import ../sources/openclaw-source.nix
, steipetePkgs ? {}
, toolNamesOverride ? null
, excludeToolNames ? []
}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  toolSets = import ../tools/extended.nix {
    pkgs = pkgs;
    steipetePkgs = steipetePkgs;
    inherit toolNamesOverride excludeToolNames;
  };
  openclawGateway = pkgs.callPackage ./openclaw-gateway.nix {
    inherit sourceInfo;
    pnpmDepsHash = sourceInfo.pnpmDepsHash or null;
  };
  openclawApp = if isDarwin then pkgs.callPackage ./openclaw-app.nix { } else null;
  openclawTools = pkgs.buildEnv {
    name = "openclaw-tools";
    paths = toolSets.tools;
    pathsToLink = [ "/bin" ];
  };
  openclawBundle = pkgs.callPackage ./openclaw-batteries.nix {
    openclaw-gateway = openclawGateway;
    openclaw-app = openclawApp;
    extendedTools = toolSets.tools;
  };
in {
  openclaw-gateway = openclawGateway;
  openclaw = openclawBundle;
  openclaw-tools = openclawTools;
} // (if isDarwin then { openclaw-app = openclawApp; } else {})
