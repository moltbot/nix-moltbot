{ config, lib, pkgs, ... }:

let
  openclawLib = import ./lib.nix { inherit config lib pkgs; };
  instanceModule = import ./options-instance.nix { inherit lib openclawLib; };
  mkSkillOption = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Skill name (used as the directory name).";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Short description for the skill frontmatter.";
      };
      homepage = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Optional homepage URL for the skill frontmatter.";
      };
      body = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Optional skill body (markdown).";
      };
      openclaw = lib.mkOption {
        type = lib.types.nullOr lib.types.attrs;
        default = null;
        description = "Optional openclaw metadata for the skill frontmatter.";
      };
      mode = lib.mkOption {
        type = lib.types.enum [ "symlink" "copy" "inline" ];
        default = "symlink";
        description = "Install mode for the skill (symlink/copy/inline).";
      };
      source = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Source path for the skill (required for symlink/copy).";
      };
    };
  };

in {
  options.programs.openclaw = {
    enable = lib.mkEnableOption "Openclaw (batteries-included)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.openclaw;
      description = "Openclaw batteries-included package.";
    };

    toolNames = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = "Override the built-in toolchain names (see nix/tools/extended.nix).";
    };

    excludeTools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Tool names to remove from the built-in toolchain.";
    };

    appPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Optional Openclaw app package (defaults to package if unset).";
    };

    installApp = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Openclaw.app at the default location.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "${openclawLib.homeDir}/.openclaw";
      description = "State directory for Openclaw (logs, sessions, config).";
    };

    workspaceDir = lib.mkOption {
      type = lib.types.str;
      default = "${openclawLib.homeDir}/.openclaw/workspace";
      description = "Workspace directory for Openclaw agent skills.";
    };

    documents = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to a documents directory containing AGENTS.md, SOUL.md, and TOOLS.md.";
    };

    skills = lib.mkOption {
      type = lib.types.listOf mkSkillOption;
      default = [];
      description = "Declarative skills installed into each instance workspace.";
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
      default = [];
      description = "Plugins enabled for the default instance (merged with first-party toggles).";
    };

    firstParty = {
      summarize.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the summarize plugin (first-party).";
      };
      peekaboo.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the peekaboo plugin (first-party).";
      };
      oracle.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the oracle plugin (first-party).";
      };
      poltergeist.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the poltergeist plugin (first-party).";
      };
      sag.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the sag plugin (first-party).";
      };
      camsnap.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the camsnap plugin (first-party).";
      };
      gogcli.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the gogcli plugin (first-party).";
      };
      goplaces.enable = lib.mkOption {
        type = lib.types.bool;
        default = pkgs.stdenv.hostPlatform.isDarwin;
        description = "Enable the goplaces plugin (first-party).";
      };
      bird.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the bird plugin (first-party).";
      };
      sonoscli.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the sonoscli plugin (first-party).";
      };
      imsg.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the imsg plugin (first-party).";
      };
    };

    launchd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run Openclaw gateway via launchd (macOS).";
    };

    systemd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run Openclaw gateway via systemd user service (Linux).";
    };

    instances = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule instanceModule);
      default = {};
      description = "Named Openclaw instances (prod/test).";
    };

    exposePluginPackages = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add plugin packages to home.packages so CLIs are on PATH.";
    };

    reloadScript = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install openclaw-reload helper for no-sudo config refresh + gateway restart.";
      };
    };

    config = lib.mkOption {
      type = lib.types.submodule { options = openclawLib.generatedConfigOptions; };
      default = {};
      description = "Openclaw config (schema-typed).";
    };
  };
}
