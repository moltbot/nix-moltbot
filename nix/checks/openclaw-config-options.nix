{ lib
, pkgs
, stdenv
, fetchFromGitHub
, fetchurl
, nodejs_22
, pnpm_10
, pkg-config
, jq
, python3
, node-gyp
, git
, zstd
, sourceInfo
, pnpmDepsHash ? (sourceInfo.pnpmDepsHash or null)
}:

let
  linuxFirstParty = [
    "summarize"
    "gogcli"
    "camsnap"
    "sonoscli"
    "sag"
    "oracle"
  ];
  enableFirstParty = name: stdenv.hostPlatform.isDarwin || lib.elem name linuxFirstParty;

  stubModule = { lib, ... }: {
    options = {
      assertions = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [];
      };

      home.homeDirectory = lib.mkOption {
        type = lib.types.str;
        default = "/tmp";
      };

      home.packages = lib.mkOption {
        type = lib.types.listOf lib.types.anything;
        default = [];
      };

      home.file = lib.mkOption {
        type = lib.types.attrs;
        default = {};
      };

      home.activation = lib.mkOption {
        type = lib.types.attrs;
        default = {};
      };

      launchd.agents = lib.mkOption {
        type = lib.types.attrs;
        default = {};
      };

      systemd.user.services = lib.mkOption {
        type = lib.types.attrs;
        default = {};
      };

      programs.git.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      lib = lib.mkOption {
        type = lib.types.attrs;
        default = {};
      };
    };
  };

  pluginEval = lib.evalModules {
    modules = [
      stubModule
      ../modules/home-manager/openclaw.nix
      ({ lib, options, ... }: {
        config = {
          home.homeDirectory = "/tmp";
          programs.git.enable = false;
          lib.file.mkOutOfStoreSymlink = path: path;
          programs.openclaw = {
            enable = true;
            launchd.enable = false;
            systemd.enable = false;
            instances.default = {};
            firstParty = lib.mapAttrs (name: _: { enable = enableFirstParty name; }) options.programs.openclaw.firstParty;
          };
        };
      })
    ];
    specialArgs = { inherit pkgs; };
  };

  pluginEvalKey = builtins.deepSeq pluginEval.config.assertions "ok";

  sourceFetch = lib.removeAttrs sourceInfo [ "pnpmDepsHash" ];
  pnpmPlatform = if stdenv.hostPlatform.isDarwin then "darwin" else "linux";
  pnpmArch = if stdenv.hostPlatform.isAarch64 then "arm64" else "x64";
  nodeAddonApi = stdenv.mkDerivation {
    pname = "node-addon-api";
    version = "8.5.0";
    src = fetchurl {
      url = "https://registry.npmjs.org/node-addon-api/-/node-addon-api-8.5.0.tgz";
      hash = "sha256-0S8HyBYig7YhNVGFXx2o2sFiMxN0YpgwteZA8TDweRA=";
    };
    dontConfigure = true;
    dontBuild = true;
    installPhase = "${../scripts/node-addon-api-install.sh}";
  };

in

stdenv.mkDerivation (finalAttrs: {
  pname = "openclaw-config-options";
  version = "2026.1.8-2";

  src = fetchFromGitHub sourceFetch;

  pnpmDeps = pnpm_10.fetchDeps {
    inherit (finalAttrs) pname version src;
    hash = if pnpmDepsHash != null
      then pnpmDepsHash
      else lib.fakeHash;
    fetcherVersion = 2;
    npm_config_arch = pnpmArch;
    npm_config_platform = pnpmPlatform;
    nativeBuildInputs = [ git ];
  };

  nativeBuildInputs = [
    nodejs_22
    pnpm_10
    pkg-config
    jq
    python3
    node-gyp
    zstd
  ];

  env = {
    npm_config_arch = pnpmArch;
    npm_config_platform = pnpmPlatform;
    PNPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS = "false";
    npm_config_nodedir = nodejs_22;
    npm_config_python = python3;
    NODE_PATH = "${nodeAddonApi}/lib/node_modules:${node-gyp}/lib/node_modules";
    PNPM_DEPS = finalAttrs.pnpmDeps;
    NODE_GYP_WRAPPER_SH = "${../scripts/node-gyp-wrapper.sh}";
    GATEWAY_PREBUILD_SH = "${../scripts/gateway-prebuild.sh}";
    PROMOTE_PNPM_INTEGRITY_SH = "${../scripts/promote-pnpm-integrity.sh}";
    REMOVE_PACKAGE_MANAGER_FIELD_SH = "${../scripts/remove-package-manager-field.sh}";
    STDENV_SETUP = "${stdenv}/setup";
    CONFIG_OPTIONS_GENERATOR = "${../scripts/generate-config-options.ts}";
    CONFIG_OPTIONS_GOLDEN = "${../generated/openclaw-config-options.nix}";
    NODE_ENGINE_CHECK = "${../scripts/check-node-engine.ts}";
    OPENCLAW_PLUGIN_EVAL = pluginEvalKey;
  };

  buildPhase = "${../scripts/gateway-tests-build.sh}";
  postPatch = "${../scripts/gateway-postpatch.sh}";

  doCheck = true;
  checkPhase = "${../scripts/config-options-check.sh}";

  installPhase = "${../scripts/empty-install.sh}";
  dontPatchShebangs = true;
})
