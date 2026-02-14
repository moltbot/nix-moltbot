{ lib, openclawLib }:

{ name, config, ... }:
{
  options = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable this OpenClaw instance.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = openclawLib.defaultPackage;
      description = "OpenClaw batteries-included package.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = if name == "default"
        then "${openclawLib.homeDir}/.openclaw"
        else "${openclawLib.homeDir}/.openclaw-${name}";
      description = "State directory for this OpenClaw instance (logs, sessions, config).";
    };

    workspaceDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.stateDir}/workspace";
      description = "Workspace directory for this OpenClaw instance.";
    };

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.stateDir}/openclaw.json";
      description = "Path to generated OpenClaw config JSON.";
    };

    logPath = lib.mkOption {
      type = lib.types.str;
      default = if name == "default"
        then "/tmp/openclaw/openclaw-gateway.log"
        else "/tmp/openclaw/openclaw-gateway-${name}.log";
      description = "Log path for this OpenClaw gateway instance.";
    };

    gatewayPort = lib.mkOption {
      type = lib.types.int;
      default = 18789;
      description = "Gateway port used by the OpenClaw desktop app.";
    };

    gatewayPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Local path to OpenClaw gateway source (dev only).";
    };

    gatewayPnpmDepsHash = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = lib.fakeHash;
      description = "pnpmDeps hash for local gateway builds (omit to let Nix suggest the correct hash).";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          source = lib.mkOption {
            type = lib.types.str;
            description = "Plugin source pointer (e.g., github:owner/repo or path:/...).";
          };
          config = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "Plugin-specific configuration (env/files/etc).";
          };
        };
      });
      default = openclawLib.effectivePlugins;
      description = "Plugins enabled for this instance (includes first-party toggles).";
    };

    config = lib.mkOption {
      type = lib.types.submodule { options = openclawLib.generatedConfigOptions; };
      default = {};
      description = "OpenClaw config (schema-typed).";
    };

    launchd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run OpenClaw gateway via launchd (macOS).";
    };

    launchd.label = lib.mkOption {
      type = lib.types.str;
      default = if name == "default"
        then "com.steipete.openclaw.gateway"
        else "com.steipete.openclaw.gateway.${name}";
      description = "launchd label for this instance.";
    };

    systemd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run OpenClaw gateway via systemd user service (Linux).";
    };

    systemd.unitName = lib.mkOption {
      type = lib.types.str;
      default = if name == "default"
        then "openclaw-gateway"
        else "openclaw-gateway-${name}";
      description = "systemd user service unit name for this instance.";
    };

    app.install.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install OpenClaw.app for this instance.";
    };

    app.install.path = lib.mkOption {
      type = lib.types.str;
      default = "${openclawLib.homeDir}/Applications/OpenClaw.app";
      description = "Destination path for this instance's OpenClaw.app bundle.";
    };

    appDefaults = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = name == "default";
        description = "Configure macOS app defaults for this instance.";
      };

      attachExistingOnly = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Attach existing gateway only (macOS).";
      };

      nixMode = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable OpenClaw Nix mode in the macOS app via defaults (openclaw.nixMode).";
      };
    };
  };
}
