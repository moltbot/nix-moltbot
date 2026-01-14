{ pkgs
, sourceInfo ? import ../sources/clawdbot-source.nix
, steipetePkgs ? {}
}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  steipetePkgsPatched =
    if steipetePkgs ? summarize then
      steipetePkgs // {
        summarize = steipetePkgs.summarize.overrideAttrs (old: {
          env = (old.env or {}) // {
            PNPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS = "false";
          };
          postPatch = (old.postPatch or "") + ''
            if [ -f package.json ]; then
              python3 - <<'PY'
import json
from pathlib import Path

path = Path("package.json")
if path.exists():
    data = json.loads(path.read_text())
    if "packageManager" in data:
        data.pop("packageManager", None)
        path.write_text(json.dumps(data, indent=2) + "\n")
PY
            fi
          '';
        });
      }
    else
      steipetePkgs;
  toolSets = import ../tools/extended.nix {
    pkgs = pkgs;
    steipetePkgs = steipetePkgsPatched;
  };
  clawdbotGateway = pkgs.callPackage ./clawdbot-gateway.nix {
    inherit sourceInfo;
    pnpmDepsHash = sourceInfo.pnpmDepsHash or null;
  };
  clawdbotApp = if isDarwin then pkgs.callPackage ./clawdbot-app.nix { } else null;
  clawdbotTools = pkgs.buildEnv {
    name = "clawdbot-tools";
    paths = toolSets.tools;
  };
  clawdbotBundle = pkgs.callPackage ./clawdbot-batteries.nix {
    clawdbot-gateway = clawdbotGateway;
    clawdbot-app = clawdbotApp;
    extendedTools = toolSets.tools;
  };
in {
  clawdbot-gateway = clawdbotGateway;
  clawdbot = clawdbotBundle;
  clawdbot-tools = clawdbotTools;
} // (if isDarwin then { clawdbot-app = clawdbotApp; } else {})
