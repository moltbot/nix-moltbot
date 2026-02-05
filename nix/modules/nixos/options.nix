# NixOS module options for Openclaw system service
#
# TODO: Consolidate with home-manager/openclaw.nix options
# This file duplicates option definitions for NixOS system service support.
# The duplication is intentional to avoid risking the stable home-manager module
# while adding NixOS support. Once patterns stabilize, extract shared options.
#
# Key differences from home-manager:
# - Namespace: services.openclaw (not programs.openclaw)
# - Paths: /var/lib/openclaw (not ~/.openclaw)
# - Adds: user, group options for system user
# - Removes: launchd.*, app.*, appDefaults.* (macOS-specific)
# - systemd options are for system services (not user services)

{ lib, cfg, defaultPackage }:

let
  stateDir = "/var/lib/openclaw";

  instanceModule = { name, config, ... }: {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable this Openclaw instance.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = defaultPackage;
        description = "Openclaw batteries-included package.";
      };

      stateDir = lib.mkOption {
        type = lib.types.str;
        default = if name == "default"
          then stateDir
          else "${stateDir}-${name}";
        description = "State directory for this Openclaw instance.";
      };

      workspaceDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.stateDir}/workspace";
        description = "Workspace directory for this Openclaw instance.";
      };

      configPath = lib.mkOption {
        type = lib.types.str;
        default = "${config.stateDir}/openclaw.json";
        description = "Path to generated Openclaw config JSON.";
      };

      gatewayPort = lib.mkOption {
        type = lib.types.int;
        default = 18789;
        description = "Gateway port for this Openclaw instance.";
      };

      providers.telegram = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = cfg.providers.telegram.enable;
          description = "Enable Telegram provider.";
        };

        botTokenFile = lib.mkOption {
          type = lib.types.str;
          default = cfg.providers.telegram.botTokenFile;
          description = "Path to Telegram bot token file.";
        };

        allowFrom = lib.mkOption {
          type = lib.types.listOf lib.types.int;
          default = cfg.providers.telegram.allowFrom;
          description = "Allowed Telegram chat IDs.";
        };

        groups = lib.mkOption {
          type = lib.types.attrs;
          default = {};
          description = "Per-group Telegram overrides.";
        };
      };

      providers.anthropic = {
        apiKeyFile = lib.mkOption {
          type = lib.types.str;
          default = cfg.providers.anthropic.apiKeyFile;
          description = "Path to Anthropic API key file (sets ANTHROPIC_API_KEY).";
        };

        oauthTokenFile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = cfg.providers.anthropic.oauthTokenFile;
          description = ''
            Path to file containing an Anthropic OAuth token (sets ANTHROPIC_OAUTH_TOKEN).
            Generate with `claude setup-token` - these tokens are long-lived.
            This is the recommended auth method for headless/server deployments.
          '';
          example = "/run/agenix/openclaw-anthropic-token";
        };
      };

      plugins = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            source = lib.mkOption {
              type = lib.types.str;
              description = "Plugin source pointer (e.g., github:owner/repo).";
            };
            config = lib.mkOption {
              type = lib.types.attrs;
              default = {};
              description = "Plugin-specific configuration.";
            };
          };
        });
        default = [];
        description = "Plugins enabled for this instance.";
      };

      agent = {
        model = lib.mkOption {
          type = lib.types.str;
          default = cfg.defaults.model;
          description = "Default model for this instance.";
        };
        thinkingDefault = lib.mkOption {
          type = lib.types.enum [ "off" "minimal" "low" "medium" "high" ];
          default = cfg.defaults.thinkingDefault;
          description = "Default thinking level for this instance.";
        };
      };

      routing.queue = {
        mode = lib.mkOption {
          type = lib.types.enum [ "queue" "interrupt" ];
          default = "interrupt";
          description = "Queue mode when a run is active.";
        };

        byChannel = lib.mkOption {
          type = lib.types.attrs;
          default = {
            telegram = "interrupt";
            discord = "queue";
            webchat = "queue";
          };
          description = "Per-channel queue mode overrides.";
        };
      };

      gateway.auth = {
        mode = lib.mkOption {
          type = lib.types.enum [ "token" "password" ];
          default = cfg.gateway.auth.mode;
          description = "Gateway authentication mode.";
        };

        tokenFile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = cfg.gateway.auth.tokenFile;
          description = ''
            Path to file containing the gateway authentication token.
            Required when auth mode is "token".
          '';
          example = "/run/agenix/openclaw-gateway-token";
        };

        passwordFile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = cfg.gateway.auth.passwordFile;
          description = ''
            Path to file containing the gateway authentication password.
            Required when auth mode is "password".
          '';
          example = "/run/agenix/openclaw-gateway-password";
        };
      };

      configOverrides = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Additional config to merge into generated JSON.";
      };
    };
  };

in {
  inherit instanceModule;

  # Top-level options for services.openclaw
  topLevelOptions = {
    enable = lib.mkEnableOption "Openclaw system service";

    package = lib.mkOption {
      type = lib.types.package;
      description = "Openclaw batteries-included package.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "openclaw";
      description = "System user to run the Openclaw gateway.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "openclaw";
      description = "System group for the Openclaw user.";
    };

    toolNames = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = "Override the built-in toolchain names.";
    };

    excludeTools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Tool names to remove from the built-in toolchain.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = stateDir;
      description = "State directory for Openclaw.";
    };

    workspaceDir = lib.mkOption {
      type = lib.types.str;
      default = "${stateDir}/workspace";
      description = "Workspace directory for Openclaw agent skills.";
    };

    documents = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to documents directory (AGENTS.md, SOUL.md, TOOLS.md).";
    };

    skills = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Skill name (directory name).";
          };
          description = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Short description for skill frontmatter.";
          };
          homepage = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional homepage URL.";
          };
          body = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Optional skill body (markdown).";
          };
          openclaw = lib.mkOption {
            type = lib.types.nullOr lib.types.attrs;
            default = null;
            description = "Optional openclaw metadata.";
          };
          mode = lib.mkOption {
            type = lib.types.enum [ "copy" "inline" ];
            default = "copy";
            description = "Install mode for the skill (symlink not supported for system service).";
          };
          source = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Source path for the skill (required for copy mode).";
          };
        };
      });
      default = [];
      description = "Declarative skills installed into workspace.";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          source = lib.mkOption {
            type = lib.types.str;
            description = "Plugin source pointer.";
          };
          config = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "Plugin-specific configuration.";
          };
        };
      });
      default = [];
      description = "Plugins enabled for the default instance.";
    };

    defaults = {
      model = lib.mkOption {
        type = lib.types.str;
        default = "anthropic/claude-sonnet-4-20250514";
        description = "Default model for all instances.";
      };
      thinkingDefault = lib.mkOption {
        type = lib.types.enum [ "off" "minimal" "low" "medium" "high" ];
        default = "high";
        description = "Default thinking level for all instances.";
      };
    };

    providers.telegram = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Telegram provider.";
      };

      botTokenFile = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to Telegram bot token file.";
      };

      allowFrom = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [];
        description = "Allowed Telegram chat IDs.";
      };
    };

    providers.anthropic = {
      apiKeyFile = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to Anthropic API key file (sets ANTHROPIC_API_KEY).";
      };

      oauthTokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Path to file containing an Anthropic OAuth token (sets ANTHROPIC_OAUTH_TOKEN).
          Generate with `claude setup-token` - these tokens are long-lived.
          This is the recommended auth method for headless/server deployments.
        '';
        example = "/run/agenix/openclaw-anthropic-token";
      };
    };

    routing.queue = {
      mode = lib.mkOption {
        type = lib.types.enum [ "queue" "interrupt" ];
        default = "interrupt";
        description = "Queue mode when a run is active.";
      };

      byChannel = lib.mkOption {
        type = lib.types.attrs;
        default = {
          telegram = "interrupt";
          discord = "queue";
          webchat = "queue";
        };
        description = "Per-channel queue mode overrides.";
      };
    };

    gateway.auth = {
      mode = lib.mkOption {
        type = lib.types.enum [ "token" "password" ];
        default = "token";
        description = "Gateway authentication mode.";
      };

      tokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Path to file containing the gateway authentication token.
          Required when auth mode is "token".
        '';
        example = "/run/agenix/openclaw-gateway-token";
      };

      passwordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Path to file containing the gateway authentication password.
          Required when auth mode is "password".
        '';
        example = "/run/agenix/openclaw-gateway-password";
      };
    };
  };
}
