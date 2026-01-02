# nix-clawdis

> Declarative Clawdis. Bulletproof by default.
>
> <sub>[skip to agent copypasta](#give-this-to-your-ai-agent)</sub>

## The Magic

- **One flake, everything works.** Gateway, macOS app, whisper, spotify, camera tools - all wired up and pinned.

- **Agent-first.** Give the copypasta to Claude. It sets you up. You don't read docs, you just talk to your bot.

- **Bulletproof.** Nix locks every dependency. No version drift, no surprises. `home-manager switch` to update, `home-manager generations` to rollback instantly.

## Why this exists

Clawdis is the right product. An AI assistant that lives in Telegram, controls your Mac, and actually does things.

This repo wraps it in Nix: a pinned, reproducible package that installs the gateway, the macOS app, and all the tools declaratively. Every dependency locked. Every update intentional. Rollback in seconds.

## What it does

```
Me: "what's on my screen?"
Bot: *takes screenshot, describes it*

Me: "play some jazz"
Bot: *opens Spotify, plays jazz*

Me: "transcribe this voice note"
Bot: *runs whisper, sends you text*
```

You talk to Telegram, your Mac does things.

## Give this to your AI agent

Copy this entire block and paste it to Claude, Cursor, or whatever you use:

```text
I want to set up nix-clawdis on my Mac.

Repository: github:joshp123/nix-clawdis

What nix-clawdis is:
- Batteries-included Nix package for Clawdis (AI assistant gateway)
- Installs gateway + macOS app + tools (whisper, spotify, cameras, etc)
- Runs as a launchd service, survives reboots

What I need you to do:
1. Check if Determinate Nix is installed (if not, install it)
2. Create a local flake at ~/code/clawdis-local using templates/agent-first/flake.nix
3. Help me create a Telegram bot (@BotFather) and get my chat ID (@userinfobot)
4. Set up secrets (bot token, Anthropic key) - plain files at ~/.secrets/ is fine
5. Fill in the template placeholders and run home-manager switch
6. Verify: launchd running, bot responds to messages

My setup:
- macOS version: [FILL IN]
- CPU: [arm64 / x86_64]
- Home Manager config name: [FILL IN or "I don't have Home Manager yet"]

Reference the README and templates/agent-first/flake.nix in the repo for the module options.
```

## Minimal config

```nix
{
  programs.clawdis = {
    enable = true;
    providers.telegram = {
      enable = true;
      botTokenFile = "/path/to/telegram-bot-token";
      allowFrom = [ 12345678 ];  # your Telegram user ID
    };
    providers.anthropic = {
      apiKeyFile = "/path/to/anthropic-api-key";
    };
  };
}
```

Then: `home-manager switch --flake .#youruser`

## What you get

- Launchd keeps the gateway alive (`com.steipete.clawdis.gateway`)
- Logs at `/tmp/clawdis/clawdis-gateway.log`
- Message your bot in Telegram, get a response
- All the tools: whisper, spotify_player, camsnap, peekaboo, and more

## What we manage vs what you manage

| Component | Nix manages | You manage |
| --- | --- | --- |
| Gateway binary | ✓ | |
| macOS app | ✓ | |
| Launchd service | ✓ | |
| Tools (whisper, etc) | ✓ | |
| Telegram bot token | | ✓ |
| Anthropic API key | | ✓ |
| Chat IDs | | ✓ |

## Module options

```nix
programs.clawdis = {
  enable = true;
  package = pkgs.clawdis;  # or clawdis-gateway for minimal
  stateDir = "~/.clawdis";
  workspaceDir = "~/.clawdis/workspace";

  providers.telegram = {
    enable = true;
    botTokenFile = "/path/to/token";
    allowFrom = [ 12345678 -1001234567890 ];  # user IDs and group IDs
    requireMention = false;  # require @mention in groups
  };

  providers.anthropic = {
    apiKeyFile = "/path/to/key";
  };

  routing.queue.mode = "interrupt";  # or "queue"
  routing.groupChat.requireMention = false;

  launchd.enable = true;
};
```

## Packages

| Package | Contents |
| --- | --- |
| `clawdis` (default) | Gateway + app + full toolchain |
| `clawdis-gateway` | Gateway CLI only |
| `clawdis-app` | macOS app only |

## Included tools

**Core**: nodejs, pnpm, git, curl, jq, python3, ffmpeg, ripgrep

**AI/ML**: openai-whisper, sag (TTS)

**Media**: spotify-player, sox, camsnap

**macOS**: peekaboo, imsg, blucli

**Integrations**: gogcli, wacli, bird, mcporter

## Commands

```bash
# Check service
launchctl print gui/$UID/com.steipete.clawdis.gateway | grep state

# View logs
tail -50 /tmp/clawdis/clawdis-gateway.log

# Restart
launchctl kickstart -k gui/$UID/com.steipete.clawdis.gateway

# Rollback
home-manager generations  # list
home-manager switch --rollback  # revert
```

## Upstream

Wraps [Clawdis](https://github.com/steipete/clawdis) by Peter Steinberger.

## License

MIT
