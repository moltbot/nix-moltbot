# nix-openclaw

> Declarative Openclaw. Bulletproof by default.
>
> macOS + Linux (headless). Windows is out of scope for now.
>
> <sub>Questions? Join the Openclaw Discord and ask in **#golden-path-deployments**: https://discord.com/channels/1456350064065904867/1457003026412736537</sub>

## Table of Contents

- [What You Get](#what-you-get)
- [Requirements](#requirements)
- [Why Nix?](#why-nix)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [Plugins](#plugins)
- [Configuration](#configuration)
- [Advanced](#advanced)
- [Packaging & Updates](#packaging--updates)
- [Reference](#reference)
- [Philosophy](#philosophy)

---

## What You Get

```
Me: "what's on my screen?"
Bot: *takes screenshot, describes it*

Me: "play some jazz"
Bot: *opens Spotify, plays jazz*

Me: "transcribe this voice note"
Bot: *runs whisper, sends you text*
```

You talk to Telegram, your machine does things.

**One flake, everything works.** Gateway + tools everywhere; macOS app on macOS.

**Plugins are self-contained.** Each plugin declares its CLI tools in Nix. You enable it, the build and wiring happens automatically.

**Bulletproof.** Nix locks every dependency. No version drift, no surprises. `home-manager switch` to update, `home-manager generations` to rollback instantly.

---

## Requirements

1. **macOS** (Apple Silicon or Intel) or **Linux** (x86_64)
2. **[Determinate Nix](https://docs.determinate.systems/determinate-nix/)** installed on your machine

That's it. The Quick Start will guide you through everything else.

> **Don't have Nix yet?** Follow the Determinate Nix install guide, then come back here.

---

## Why Nix?

You've probably installed tools before. Homebrew, pip, npm - they work until they don't.

**What you deal with today:**
- Update one thing, break another ("but it worked yesterday")
- Reinstall everything after a macOS upgrade
- "Works on my machine" when sharing setups
- No easy way to undo a bad update

**What Nix gives you:**
- Every dependency pinned to exact versions. Forever.
- Update breaks something? `home-manager switch --rollback` - back in 30 seconds.
- Share your config file, get the exact same setup on another machine.
- **Plugins just work.** Add a GitHub URL, run one command, done. Nix handles the build, dependencies, and wiring.
- Tools don't pollute your system - they live in isolation.

You don't need to learn Nix deeply. You describe what you want, Nix figures out how to build it.

<details>
<summary><strong>How it actually works</strong></summary>

![On declarative build systems](docs/images/on-declarative-build-systems.png)

Nix is a **declarative package manager**. Instead of running commands to install things, you write a config file that says "I want these tools at these versions." Nix reads that file and builds everything in `/nix/store` - isolated from your system.

**The hashing magic:** Every package in Nix is identified by a cryptographic hash of *all* its inputs - source code, dependencies, build flags, everything. Change anything, get a different hash. This means:
- Two machines with the same hash have *identical* builds. Byte-for-byte.
- Old versions stick around (different hash = different path). Nothing gets overwritten.
- Rollback is instant - just point to the old hash.

**Key terms you'll see:**
- **Flake**: A config file (`flake.nix`) that pins all your dependencies. Think `package-lock.json` but for your entire system.
- **Home Manager**: Manages your user config (dotfiles, apps, services) through Nix.
- **`home-manager switch`**: The command that applies your config. Run it after any change.

</details>

---

## Quick Start

### Option 1: Let your agent set it up (recommended)

Copy this entire block and paste it to Claude, Cursor, or your preferred AI assistant:

```text
I want to set up nix-openclaw on my machine (macOS or Linux).

Repository: github:openclaw/nix-openclaw

What nix-openclaw is:
- Batteries-included Nix package for Openclaw (AI assistant gateway)
- Installs gateway + tools everywhere; macOS app only on macOS
- Runs as a launchd service on macOS, systemd user service on Linux

What I need you to do:
1. Check if Determinate Nix is installed (if not, install it)
2. Create a local flake at ~/code/openclaw-local using templates/agent-first/flake.nix
3. Create a docs dir next to the config (e.g., ~/code/openclaw-local/documents) with AGENTS.md, SOUL.md, TOOLS.md
   - If ~/.openclaw/workspace already has these files, adopt them into the documents dir first
4. Help me create a Telegram bot (@BotFather) and get my chat ID (@userinfobot)
5. Set up secrets (bot token, Anthropic key) - plain files at ~/.secrets/ is fine
6. Fill in the template placeholders and run home-manager switch
7. Verify: service running, bot responds to messages

My setup:
- OS: [macOS / Linux]
- CPU: [arm64 / x86_64]
- System: [aarch64-darwin / x86_64-darwin / x86_64-linux]
- Home Manager config name: [FILL IN or "I don't have Home Manager yet"]

Reference the README and templates/agent-first/flake.nix in the repo for the module options.
```

Your agent will install Nix, create your config, and get Openclaw running. You just answer its questions.

**What happens next:**
1. Your agent sets everything up and runs `home-manager switch`
2. You message your Telegram bot for the first time
3. Openclaw runs its **bootstrap ritual** - it asks you playful questions: *"Who am I? What am I? Who are you?"* - to learn its identity and yours
4. Once you've named it and introduced yourself, the bootstrap is done. You're up and running.

<details>
<summary><strong>Option 2: Manual setup</strong></summary>

### macOS (Home Manager + launchd)

1. Install Determinate Nix.
2. Create a local config:
   ```bash
   mkdir -p ~/code/openclaw-local && cd ~/code/openclaw-local
   nix flake init -t github:openclaw/nix-openclaw#agent-first
   ```
3. Edit `flake.nix` placeholders:
   - `system` = `aarch64-darwin` (Apple Silicon) or `x86_64-darwin` (Intel)
   - `home.username` and `home.homeDirectory`
   - `programs.openclaw.documents` with `AGENTS.md`, `SOUL.md`, `TOOLS.md`
   - Provider secrets (Telegram/Discord tokens, Anthropic API key)
4. Apply:
   ```bash
   home-manager switch --flake .#<user>
   ```
5. Verify:
   ```bash
   launchctl print gui/$UID/com.steipete.openclaw.gateway | grep state
   ```

### Linux (headless + systemd user service)

1. Install Determinate Nix.
2. Create a local config:
   ```bash
   mkdir -p ~/code/openclaw-local && cd ~/code/openclaw-local
   nix flake init -t github:openclaw/nix-openclaw#agent-first
   ```
3. Edit `flake.nix` placeholders:
   - `system` = `x86_64-linux`
   - `home.username` and `home.homeDirectory` (e.g., `/home/<user>`)
   - `programs.openclaw.documents` with `AGENTS.md`, `SOUL.md`, `TOOLS.md`
   - Provider secrets (Telegram/Discord tokens, Anthropic API key)
4. Apply:
   ```bash
   home-manager switch --flake .#<user>
   ```
5. Verify:
   ```bash
   systemctl --user status openclaw-gateway
   journalctl --user -u openclaw-gateway -f
   ```

</details>

---

## How It Works

```
You (Telegram/Discord) --> Gateway --> Tools --> Your machine does things
```

**Gateway**: The brain. A service running on your machine that receives messages and decides what to do. Managed by launchd on macOS and a systemd user service on Linux.

**Plugins**: Bundles that contain two things:
1. **CLI tools** - actual programs that do stuff (take screenshots, control Spotify, transcribe audio)
2. **Skills** - markdown files that teach the AI *how* to use those tools

When you enable a plugin, Nix installs the tools and wires up the skills to Openclaw automatically - the gateway learns what it can do.

**Skills**: Instructions for the AI. A skill file says "when the user wants X, run this command." The AI reads these to know what it can do.

<details>
<summary><strong>Under the hood</strong></summary>

When you run `home-manager switch`:

1. Nix reads your `flake.nix` and resolves all plugin sources (GitHub repos, local paths)
2. For each plugin, Nix looks for a `openclawPlugin` output that declares:
   - What CLI packages to install
   - What skill files to copy
   - What environment variables it needs
3. Tools go on your PATH, skills get symlinked to `~/.openclaw/workspace/skills/`
4. A launchd (macOS) or systemd user service (Linux) is created/updated to run the gateway
5. The gateway starts, loads skills, connects to your providers

All state lives in `~/.openclaw/`. Logs at `/tmp/openclaw/openclaw-gateway.log`.

</details>

---

## Plugins

> **Note:** Complete the [Quick Start](#quick-start) first to get Openclaw running. Then come back here to add plugins.

Plugins extend what Openclaw can do. Each plugin bundles tools and teaches the AI how to use them.

### First-party plugins

These ship with nix-openclaw. Toggle them in your config:

```nix
programs.openclaw.firstParty = {
  summarize.enable = true;   # Summarize web pages, PDFs, videos
  peekaboo.enable = true;    # Take screenshots
  oracle.enable = false;     # Web search
  poltergeist.enable = false; # Control your macOS UI
  sag.enable = false;        # Text-to-speech
  camsnap.enable = false;    # Camera snapshots
  gogcli.enable = false;     # Google Calendar
  bird.enable = false;       # Twitter/X
  sonoscli.enable = false;   # Sonos control
  imsg.enable = false;       # iMessage
};
```

| Plugin | What it does |
|--------|--------------|
| `summarize` | Summarize URLs, PDFs, YouTube videos |
| `peekaboo` | Screenshot your screen |
| `oracle` | Search the web |
| `poltergeist` | Click, type, control macOS UI |
| `sag` | Text-to-speech |
| `camsnap` | Take photos from connected cameras |
| `gogcli` | Google Calendar integration |
| `bird` | Twitter/X integration |
| `sonoscli` | Control Sonos speakers |
| `imsg` | Send/read iMessages |

### Adding community plugins

Tell your agent: *"Add the plugin from github:owner/repo-name"*

Or add it manually to your config:

```nix
plugins = [
  { source = "github:owner/repo-name"; }
];
```

Then run `home-manager switch` to install.

### Plugins with configuration

Some plugins need settings (auth files, preferences). Here's a simplified example:

```nix
# Example: a padel court booking plugin (simplified for illustration)
plugins = [
  {
    source = "github:example/padel-cli";
    config = {
      env = {
        PADEL_AUTH_FILE = "~/.secrets/padel-auth";  # where your login token lives
      };
      settings = {
        default_city = "Barcelona";
        preferred_times = [ "18:00" "20:00" ];
      };
    };
  }
];
```

- `config.env` - paths to secrets/auth files the plugin needs
- `config.settings` - preferences (rendered to `config.json` for the plugin)

<details>
<summary><strong>For plugin developers</strong></summary>

Want to make your tool available as a Openclaw plugin? Here's the contract.

**Minimum structure:**

```
your-plugin/
  flake.nix          # Declares the plugin
  skills/
    your-skill/
      SKILL.md       # Instructions for the AI
```

**Your `flake.nix` must export `openclawPlugin`:**

```nix
{
  outputs = { self, nixpkgs, ... }:
    let
      pkgs = import nixpkgs { system = builtins.currentSystem; };
    in {
      openclawPlugin = {
        name = "hello-world";
        skills = [ ./skills/hello-world ];
        packages = [ pkgs.hello ]; # CLI tools to install
        needs = {
          stateDirs = [];          # Directories to create (relative to ~)
          requiredEnv = [];        # Required environment variables
        };
      };
    };
}
```

**Your `SKILL.md` teaches the AI:**

```md
---
name: hello-world
description: Prints hello world.
---

Use the `hello` CLI to print a greeting.
```

See `examples/hello-world-plugin` for a complete working example.

---

**Full plugin authoring prompt** - paste this to your AI agent to make any repo nix-openclaw-native:

```text
Goal: Make this repo a nix-openclaw-native plugin with the standard contract.

Contract to implement:
1) Add openclawPlugin output in flake.nix:
   - name
   - skills (paths to SKILL.md dirs)
   - packages (CLI packages to put on PATH)
   - needs (stateDirs + requiredEnv)

Example:
openclawPlugin = {
  name = "my-plugin";
  skills = [ ./skills/my-plugin ];
  packages = [ self.packages.${system}.default ];
  needs = {
    stateDirs = [ ".config/my-plugin" ];
    requiredEnv = [ "MYPLUGIN_AUTH_FILE" ];
  };
};

2) Make the CLI explicitly configurable by env (no magic defaults):
   - Support an auth file env (e.g., MYPLUGIN_AUTH_FILE)
   - Honor XDG_CONFIG_HOME or a plugin-specific config dir env

3) Provide AGENTS.md in the plugin repo:
   - Plain-English explanation of knobs + values
   - Generic placeholders only (no real secrets)
   - Explain where credentials live (e.g., /run/agenix/...)

4) Update SKILL.md to call the CLI by its PATH name.

Standard plugin config shape (Nix-native, no JSON strings):

plugins = [
  {
    source = "github:owner/my-plugin";
    config = {
      env = {
        MYPLUGIN_AUTH_FILE = "/run/agenix/myplugin-auth";
      };
      settings = {
        name = "EXAMPLE_NAME";
        enabled = true;
        retries = 3;
        tags = [ "alpha" "beta" ];
        window = { start = "08:00"; end = "18:00"; };
        options = { mode = "fast"; level = 2; };
      };
    };
  }
];

Config flags the host will use:
- `config.env` for required env vars (e.g., MYPLUGIN_AUTH_FILE)
- `config.settings` for typed config keys (rendered to config.json in the first stateDir)

CI note:
- If the repo uses Garnix, add the plugin build to its `garnix.yaml` (or equivalent) so CI verifies it.

Why: explicit, minimal, fail-fast, no inline JSON strings.
Deliverables: flake output, env overrides, AGENTS.md, skill update.
```

</details>

---

## Configuration

> **Note:** You probably don't need to write this yourself. Your AI agent handles this when you use the [Quick Start](#quick-start) copypasta. These examples are here for reference.

### What Openclaw needs (minimum)

1. **Telegram bot token** - create via [@BotFather](https://t.me/BotFather), save to a file
2. **Your Telegram user ID** - get from [@userinfobot](https://t.me/userinfobot)
3. **Anthropic API key** - from [console.anthropic.com](https://console.anthropic.com), save to a file

That's it. Everything else has sensible defaults.

### Minimal config (single instance)

The simplest setup:

```nix
{
  programs.openclaw = {
    enable = true;
    providers.telegram = {
      enable = true;
      botTokenFile = "/run/agenix/telegram-bot-token"; # any file path works
      allowFrom = [ 12345678 ];  # your Telegram user ID
    };
    providers.anthropic = {
      apiKeyFile = "/run/agenix/anthropic-api-key"; # any file path works
    };

    # Built-ins (tools + skills) shipped via nix-steipete-tools.
    plugins = [
      { source = "github:openclaw/nix-steipete-tools?dir=tools/summarize"; }
    ];
  };
}
```

Then: `home-manager switch --flake .#youruser`

### Sensible defaults config

Uses `instances.default` to unlock per-group mention rules. If `instances` is set, you don't need `programs.openclaw.enable`.

```nix
{
  programs.openclaw = {
    documents = ./documents;
    instances.default = {
      enable = true;
      package = pkgs.openclaw; # batteries-included
      stateDir = "~/.openclaw";
      workspaceDir = "~/.openclaw/workspace";

      providers.telegram = {
        enable = true;
        botTokenFile = "/run/agenix/telegram-bot-token";
        allowFrom = [
          12345678         # you (DM)
          -1001234567890   # couples group (no @mention required)
          -1002345678901   # noisy group (require @mention)
        ];
        groups = {
          "*" = { requireMention = true; };
          "-1001234567890" = { requireMention = false; }; # couples group
          "-1002345678901" = { requireMention = true; };  # noisy group
        };
      };

      providers.anthropic.apiKeyFile = "/run/agenix/anthropic-api-key";

      launchd.enable = true;

      # Plugins (prod: pinned GitHub). Built-ins are via nix-steipete-tools.
      # MVP target: repo pointers resolve to tools + skills automatically.
      plugins = [
        { source = "github:openclaw/nix-steipete-tools?dir=tools/oracle"; }
        { source = "github:openclaw/nix-steipete-tools?dir=tools/peekaboo"; }
        { source = "github:joshp123/xuezh"; }
        {
          source = "github:joshp123/padel-cli";
          config = {
            env = { PADEL_AUTH_FILE = "/run/agenix/padel-auth"; };
            settings = {
              default_location = "CITY_NAME";
              preferred_times = [ "18:00" "20:00" ];
              preferred_duration = 90;
              venues = [
                {
                  id = "VENUE_ID";
                  alias = "VENUE_ALIAS";
                  name = "VENUE_NAME";
                  indoor = true;
                  timezone = "TIMEZONE";
                }
              ];
            };
          };
        }
      ];
    };
  };
}
```

---

## Advanced

### Dual-instance setup (prod + dev)

Use a shared base config and override only what's different. After changing local plugin or gateway code, re-run `home-manager switch` to rebuild.

```nix
# flake inputs (pin prod + app)
inputs = {
  nix-openclaw.url = "github:openclaw/nix-openclaw?ref=v0.1.0"; # pins macOS app + gateway bundle
};

let
  prod = {
    enable = true;
    # Prod gateway pin (comes from nix-openclaw input @ v0.1.0 above).
    package = inputs.nix-openclaw.packages.${pkgs.system}.openclaw-gateway;
    providers.telegram.enable = true;
    providers.telegram.botTokenFile = "/run/agenix/telegram-prod";
    providers.telegram.allowFrom = [ 12345678 ];
    providers.anthropic.apiKeyFile = "/run/agenix/anthropic-api-key";
    plugins = [ { source = "github:owner/your-plugin"; } ];
  };
in {
  # Pinned macOS app (POC: no local app builds, uses nix-openclaw @ v0.1.0 above).
  programs.openclaw.appPackage =
    inputs.nix-openclaw.packages.${pkgs.system}.openclaw-app;
  programs.openclaw.documents = ./documents;
  programs.openclaw.instances = {
    prod = prod;
    dev = prod // {
      # Dev uses the same pinned macOS app (from nix-openclaw input),
      # but overrides the gateway package to a local checkout.
      providers.telegram.botTokenFile = "/run/agenix/telegram-dev";
      gatewayPort = 18790;
      # Local gateway checkout (path). App stays pinned.
      gatewayPath = "/Users/you/code/openclaw";
      # Local plugin overrides prod if names collide (last wins).
      plugins = prod.plugins ++ [
        { source = "path:/Users/you/code/your-plugin"; }
        {
          source = "github:joshp123/padel-cli";
          config = {
            env = { PADEL_AUTH_FILE = "/run/agenix/padel-auth-dev"; };
            settings = {
              default_location = "CITY_NAME";
              preferred_times = [ "18:00" ];
              preferred_duration = 90;
              venues = [];
            };
          };
        }
      ];
    };
  };
}
```

### Plugin collisions

Plugins are keyed by their declared `name`. If two plugins declare the same name, the **last entry wins** (use this to override a prod plugin with a local dev one).

### Tool overrides (avoid collisions)

Home Manager auto-excludes `git` when `programs.git.enable = true`.

Drop built-in tools that you already install elsewhere:

```nix
programs.openclaw.excludeTools = [ "git" "jq" "ripgrep" ];
```

Or provide a custom list:

```nix
programs.openclaw.toolNames = [ "nodejs_22" "pnpm_10" "summarize" ];
```

If you override `programs.openclaw.package`, use `pkgs.openclawPackages.withTools { ... }.openclaw` to apply these lists.

---

## Packaging & Updates

**Goal:** `nix-openclaw` is a great Nix package. Automation, promotion, and fleet rollout live elsewhere.

### Stable only (for now)

We ship a single pinned upstream commit:
- **Stable**: last known-good pin. This is the default.

Outputs:
```
.#openclaw
.#openclaw-gateway
```

Pin lives in:
- `nix/sources/openclaw-source.nix`

### Responsibilities (who owns what)

- **openclaw (upstream)**: source code, tests, releases.
- **nix-openclaw**: Nix packaging, pins, CI builds.
- **moltinators**: update cadence, smoke tests, promotion, rollout/rollback.

### Automated pipeline (no manual steps)

1) **moltinators updater** proposes a new stable pin.  
2) **Garnix** builds the package on Linux + macOS and runs `pnpm test` on Linux.  
   It also validates the generated Nix config options against the upstream schema.  
3) **moltinators smoke test** runs against real Discord in `#moltinators-test`.  
4) If green → promote to stable.  
5) If red → keep current stable pin.

---

## Reference

### Commands

```bash
# macOS: check service
launchctl print gui/$UID/com.steipete.openclaw.gateway | grep state

# macOS: view logs
tail -50 /tmp/openclaw/openclaw-gateway.log

# macOS: restart
launchctl kickstart -k gui/$UID/com.steipete.openclaw.gateway

# Linux: check service
systemctl --user status openclaw-gateway

# Linux: view logs
journalctl --user -u openclaw-gateway -f

# Linux: restart
systemctl --user restart openclaw-gateway

# Rollback
home-manager generations  # list
home-manager switch --rollback  # revert
```

### Packages

| Package | Contents |
| --- | --- |
| `openclaw` (default) | macOS: gateway + app + tools · Linux: gateway + tools (headless) |
| `openclaw-gateway` | Gateway CLI only |
| `openclaw-tools` | Toolchain bundle (gateway helpers + CLIs) |
| `openclaw-app` | macOS app only |

### What we manage vs what you manage

| Component | Nix manages | You manage |
| --- | --- | --- |
| Gateway binary | ✓ | |
| macOS app | ✓ | |
| Service (launchd/systemd) | ✓ | |
| Tools (whisper, etc) | ✓ | |
| Telegram bot token | | ✓ |
| Anthropic API key | | ✓ |
| Chat IDs | | ✓ |

### Included tools

> **Platform note:** the toolchain is filtered per platform. macOS-only tools are skipped on Linux.

**Core**: nodejs, pnpm, git, curl, jq, python3, ffmpeg, ripgrep

**First‑party tools** are sourced from `nix-steipete-tools` when available (currently aarch64‑darwin).

**AI/ML**: openai-whisper, sag (TTS)

**Media**: spotify-player, sox, camsnap

**macOS**: peekaboo, blucli

**Integrations**: gogcli, wacli, bird, mcporter

---

## Philosophy

The Zen of ~~Python~~ Openclaw, ~~by~~ shamelessly stolen from Tim Peters

Beautiful is better than ugly.
Explicit is better than implicit.
Simple is better than complex.
Complex is better than complicated.
Flat is better than nested.
Sparse is better than dense.
Readability counts.
Special cases aren't special enough to break the rules.
Although practicality beats purity.
Errors should never pass silently.
Unless explicitly silenced.
In the face of ambiguity, refuse the temptation to guess.
There should be one-- and preferably only one --obvious way to do it.
Although that way may not be obvious at first unless you're Dutch.
Now is better than never.
Although never is often better than *right* now.
If the implementation is hard to explain, it's a bad idea.
If the implementation is easy to explain, it may be a good idea.
Namespaces are one honking great idea -- let's do more of those!

---

## Upstream

Wraps [Openclaw](https://github.com/openclaw/openclaw) by Peter Steinberger.

## License

AGPL-3.0
