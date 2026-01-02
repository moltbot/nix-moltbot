{ config, lib, pkgs, ... }:

let
  cfg = config.programs.clawdis;

  stateDir = cfg.stateDir;
  workspaceDir = cfg.workspaceDir;

  baseConfig = {
    gateway = { mode = "local"; };
    agent = { workspace = workspaceDir; };
  };

  telegramConfig = lib.optionalAttrs cfg.providers.telegram.enable {
    telegram = {
      enabled = true;
      tokenFile = cfg.providers.telegram.botTokenFile;
      allowFrom = cfg.providers.telegram.allowFrom;
      requireMention = cfg.providers.telegram.requireMention;
    };
  };

  routingConfig = {
    routing = {
      queue = {
        mode = cfg.routing.queue.mode;
        bySurface = cfg.routing.queue.bySurface;
      };
      groupChat = {
        requireMention = cfg.routing.groupChat.requireMention;
      };
    };
  };

  mergedConfig = lib.recursiveUpdate baseConfig (lib.recursiveUpdate telegramConfig routingConfig);

  configJson = builtins.toJSON mergedConfig;

  logPath = "/tmp/clawdis/clawdis-gateway.log";

  gatewayWrapper = pkgs.writeShellScriptBin "clawdis-gateway" ''
    set -euo pipefail

    if [ -n "${cfg.providers.anthropic.apiKeyFile}" ]; then
      if [ ! -f "${cfg.providers.anthropic.apiKeyFile}" ]; then
        echo "Anthropic API key file not found: ${cfg.providers.anthropic.apiKeyFile}" >&2
        exit 1
      fi
      ANTHROPIC_API_KEY="$(cat "${cfg.providers.anthropic.apiKeyFile}")"
      if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "Anthropic API key file is empty: ${cfg.providers.anthropic.apiKeyFile}" >&2
        exit 1
      fi
      export ANTHROPIC_API_KEY
    fi

    exec "${cfg.package}/bin/clawdis" "$@"
  '';

in {
  options.programs.clawdis = {
    enable = lib.mkEnableOption "Clawdis (batteries-included)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.clawdis;
      description = "Clawdis batteries-included package.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.clawdis";
      description = "State directory for Clawdis (logs, sessions, config).";
    };

    workspaceDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.clawdis/workspace";
      description = "Workspace directory for Clawdis agent skills.";
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

      requireMention = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Require @mention in Telegram groups.";
      };
    };

    providers.anthropic = {
      apiKeyFile = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to Anthropic API key file (used to set ANTHROPIC_API_KEY).";
      };
    };

    routing.queue = {
      mode = lib.mkOption {
        type = lib.types.enum [ "queue" "interrupt" ];
        default = "interrupt";
        description = "Queue mode when a run is active.";
      };

      bySurface = lib.mkOption {
        type = lib.types.attrs;
        default = {
          telegram = "interrupt";
          discord = "queue";
          webchat = "queue";
        };
        description = "Per-surface queue mode overrides.";
      };
    };

    routing.groupChat.requireMention = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Require mention for group chat activation.";
    };

    launchd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run Clawdis gateway via launchd (macOS).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.providers.telegram.enable || cfg.providers.telegram.botTokenFile != "";
        message = "programs.clawdis.providers.telegram.botTokenFile must be set when Telegram is enabled.";
      }
      {
        assertion = !cfg.providers.telegram.enable || (lib.length cfg.providers.telegram.allowFrom > 0);
        message = "programs.clawdis.providers.telegram.allowFrom must be non-empty when Telegram is enabled.";
      }
    ];

    home.packages = [ cfg.package ];

    home.file."Applications/Clawdis.app" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      source = "${cfg.package}/Applications/Clawdis.app";
      recursive = true;
    };

    home.file.".clawdis/clawdis.json".text = configJson;

    home.activation.clawdisDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      /bin/mkdir -p "${stateDir}" "${workspaceDir}" "/tmp/clawdis"
    '';

    home.activation.clawdisAppDefaults = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        /usr/bin/defaults write com.steipete.clawdis clawdis.gateway.attachExistingOnly -bool true
        /usr/bin/defaults write com.steipete.clawdis gatewayPort -int 18789
      ''
    );

    launchd.agents."clawdis.gateway" = lib.mkIf cfg.launchd.enable {
      enable = true;
      config = {
        Label = "com.steipete.clawdis.gateway";
        ProgramArguments = [ "${gatewayWrapper}/bin/clawdis-gateway" ];
        RunAtLoad = true;
        KeepAlive = true;
        WorkingDirectory = stateDir;
        StandardOutPath = logPath;
        StandardErrorPath = logPath;
        EnvironmentVariables = {
          CLAWDIS_CONFIG_PATH = "${stateDir}/clawdis.json";
          CLAWDIS_STATE_DIR = stateDir;
          CLAWDIS_IMAGE_BACKEND = "sips";
          CLAWDIS_NIX_MODE = "1";
        };
      };
    };
  };
}
