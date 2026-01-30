final: prev:
let
  packages = import ./packages { pkgs = prev; };
  toolNames = (import ./tools/extended.nix { pkgs = prev; }).toolNames;
  withTools = { toolNamesOverride ? null, excludeToolNames ? [] }:
    import ./packages {
      pkgs = prev;
      inherit toolNamesOverride excludeToolNames;
    };
in
packages // {
  openclawPackages = packages // {
    inherit toolNames withTools;
  };
}
