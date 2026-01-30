# Openclaw Plugin Architecture (Maintainer Memo)

Purpose: extend Openclaw capabilities without bloating core; ship tools + skills + config as reproducible units you can pin, test, and roll back. nix-openclaw shows the contract; Openclaw core should treat the same interface as first-class, even off-Nix.

## What a Plugin Is (and is not)
- **Is:** bundle of binaries/CLIs, skills that teach the agent to use them, optional config/env requirements.
- **Not:** new transports/providers; model plumbing; secrets baked in; inline scripts or ad-hoc package-manager installs; a place for random config outside its scope.
- Why not skills-only: skills without binaries can hallucinate capability. Plugins ground skills in real tools and deliver versioned, reproducible functionality.

## Interface Contract (reference implementation: nix-openclaw)
Every plugin artifact exposes the same fields (flake output `openclawPlugin` today, but the shape is host-agnostic):

```nix
openclawPlugin = {
  name        = "summarize";                # unique; last-wins on collision
  skills      = [ ./skills/summarize ];      # dirs containing SKILL.md
  packages    = [ pkgs.summarize-cli ];      # binaries placed on PATH
  needs = {
    stateDirs   = [ ".config/summarize" ]; # created under $HOME
    requiredEnv = [ "SUMMARIZE_API_KEY" ];  # must point to files
  };
};
```

Host responsibilities (what the runtime guarantees):
- Resolve plugin source; read contract.
- Install `packages`; prepend to PATH for the gateway wrapper.
- Create `needs.stateDirs` under `$HOME`.
- Fail fast if any `requiredEnv` is unset or points to a missing/empty file.
- Copy/symlink `skills` into `workspace/skills/<name>/...`.
- If host config provides `config.settings`, render it to `config.json` in the first `stateDir`.
- Export `config.env` (plus required envs) into the gateway wrapper.
- Reject duplicate skill paths; duplicate plugin names: last entry wins.

### Host-side config shape
When enabling a plugin, the host can supply:

```nix
plugins = [
  {
    source = "github:owner/repo";
    config = {
      env = { KEY = "/run/agenix/key"; EXTRA = "/path/to/file"; };
      settings = { foo = "bar"; retries = 3; };
    };
  }
];
```

- `config.env`: values for `requiredEnv` (and any extra env to export).
- `config.settings`: JSON-rendered into `config.json` inside the first `stateDir`.
- Invariant: providing `settings` requires at least one `stateDir`.

## Dev workflow (fast iteration)
- Worktree: build and test plugins outside the core repo; point Openclaw at a local path source (e.g., `source = "path:/Users/you/code/my-plugin"`).
- Rebuild loop: change plugin → `home-manager switch` (or host-equivalent) → gateway restarts with new PATH/skills/config; no manual copying.
- Name collisions: use the same plugin `name` to override a pinned version (last entry wins); keep unique names otherwise to avoid surprise overrides.
- Skills placement: skills land under `~/.openclaw*/workspace/skills/<plugin>/...` so you can inspect quickly; delete the workspace to fully reset cached skills.
- Env guardrails: required env vars must point to files (non-empty) or the activation fails—supply temp files during dev to exercise the checks.
- Settings JSON: inspect the rendered `config.json` in the first `stateDir` to confirm schema and defaults before committing.

## Examples

### Minimal capability plugin (first-party `summarize`)
Enable (host side):

```nix
programs.openclaw.instances.default.plugins = [
  { source = "github:openclaw/nix-steipete-tools?dir=tools/summarize"; }
];
```

Plugin contract (inside the plugin repo):

```nix
openclawPlugin = {
  name = "summarize";
  skills = [ ./skills/summarize ];
  packages = [ self.packages.${system}.summarize-cli ];
  needs = { stateDirs = []; requiredEnv = []; };
};
```

### Plugin with required config/env (community `xuezh`)
Enable (host side):

```nix
programs.openclaw.instances.default.plugins = [
  {
    source = "github:joshp123/xuezh";
    config = {
      env = {
        # Required envs (guarded as files):
        XUEZH_AZURE_SPEECH_KEY_FILE = "/run/agenix/xuezh-azure-speech-key";
        XUEZH_AZURE_SPEECH_REGION   = "/run/agenix/xuezh-azure-speech-region"; # file containing e.g. "westeurope"
      };
      settings = {
        audio = {
          backend_global        = "azure.speech";
          process_voice_backend = "azure.speech";
          convert_backend       = "ffmpeg";
          tts_backend           = "edge-tts";
          inline_max_bytes      = 200000;
        };
        azure = {
          speech = {
            key_file = "/run/agenix/xuezh-azure-speech-key";
            region   = "westeurope";
          };
        };
      };
    };
  }
];
```

Plugin contract (inside `xuezh`):

```nix
openclawPlugin = {
  name = "xuezh";
  skills = [ ./skills/xuezh ];
  packages = [ self.packages.${system}.default ];
  needs = {
    stateDirs   = [ ".config/xuezh" ];
    requiredEnv = [ "XUEZH_AZURE_SPEECH_KEY_FILE" "XUEZH_AZURE_SPEECH_REGION" ];
  };
};
```

Host behavior: creates `~/.config/xuezh/config.json` from `settings`; exports both envs; fails if the pointed files are missing/empty.

## First-Party Plugin Set (current)
- summarize, peekaboo, oracle, poltergeist, sag, camsnap, gogcli, bird, sonoscli, imsg.
- Each follows the same contract: packages + skills; env/state declared via `needs`; enabled via config toggle; sources pinned (see nix-openclaw firstParty mapping).

## Authoring Rules
- Keep CLIs configurable via env; honor XDG paths; no inline scripts.
- Ship `AGENTS.md` in the plugin repo with knobs/paths (no secrets).
- `SKILL.md` should call the CLI by its PATH name (no absolute paths).
- If `config.settings` is expected, declare at least one `stateDir`.
- Add CI to build the plugin and validate `requiredEnv`/`stateDir` invariants.

## Why this approach
- Capability grounding: skills map to real tools, not hypothetical ones.
- Reproducibility: versioned bundle of tool + skill + config schema; easy rollback.
- Clean core: main Openclaw stays transport/model-focused; plugins carry integrations.
- Operational sanity: one toggle wires tools, env, skills; failure is explicit and early.
- Portability: contract is host-agnostic; Nix just enforces determinism and zero drift.
