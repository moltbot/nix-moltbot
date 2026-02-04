# Matrix Channel Configuration

**nix-openclaw** now uses Matrix as its default messaging channel (replacing Telegram). This document explains how to configure and use the Matrix integration.

---

## Overview

Openclaw connects to Matrix via the official `@openclaw/matrix` plugin. The gateway runs as a user service and communicates with your Matrix homeserver using environment variables for configuration.

### Architecture

```
You (Matrix Client) → Matrix Homeserver → Openclaw Gateway → Tools/Plugins
```

The gateway includes the Matrix plugin which:
- Connects to your homeserver using the provided credentials
- Listens for direct messages (DMs) and room invites
- Processes commands and delegates to available tools/skills
- Sends responses back through Matrix

---

## Quick Setup

### 1. Get Matrix Credentials

You need a Matrix account for the bot. You have two authentication options:

#### Option A: Access Token (Recommended)

Get an access token via the login API:

```bash
curl -X POST https://matrix.aboutco.ai/_matrix/client/v3/login \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "m.login.password",
    "identifier": {
      "type": "m.id.user",
      "user": "your-username"
    },
    "password": "your-password"
  }'
```

Save the `access_token` value to a file (e.g., `~/.secrets/matrix-token`).

#### Option B: Password

Store your password in a file (e.g., `~/.secrets/matrix-password`).

### 2. Configure nix-openclaw

Edit your `flake.nix`:

```nix
{
  programs.openclaw = {
    enable = true;
    
    documents = ./documents;
    
    # Matrix configuration (enabled by default)
    matrix = {
      enable = true;
      homeserverUrl = "https://matrix.aboutco.ai/";
      userId = "@mybot:aboutco.ai";  # Your bot's Matrix ID
      
      # Use access token (recommended)
      accessTokenFile = "~/.secrets/matrix-token";
      
      # Or use password
      # passwordFile = "~/.secrets/matrix-password";
    };
    
    instances.default = {
      enable = true;
      plugins = [
        # Add your plugins here
      ];
    };
  };
}
```

### 3. Apply Configuration

```bash
home-manager switch --flake .#<your-user>
```

### 4. Start Chatting

1. Open any Matrix client (Element, Beeper, etc.)
2. Start a direct message with your Matrix bot
3. The bot will run its **bootstrap ritual** - asking playful questions to learn its identity and yours
4. Once complete, you can start sending commands!

---

## Configuration Options

### `programs.openclaw.matrix`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | boolean | `true` | Enable Matrix channel |
| `homeserverUrl` | string | `"https://matrix.aboutco.ai/"` | Matrix homeserver URL |
| `userId` | string | `""` | Bot's Matrix user ID (e.g., `@bot:aboutco.ai`) |
| `accessTokenFile` | string | `""` | Path to file containing access token |
| `passwordFile` | string | `""` | Path to file containing password (alternative to access token) |

### Environment Variables

The following environment variables are set automatically based on your configuration:

| Variable | Description |
|----------|-------------|
| `MATRIX_HOMESERVER` | Homeserver URL |
| `MATRIX_USER_ID` | Bot user ID |
| `MATRIX_ACCESS_TOKEN` | Access token (from file) |
| `MATRIX_ACCESS_TOKEN_FILE` | Path to token file |
| `MATRIX_PASSWORD` | Password (from file) |
| `MATRIX_PASSWORD_FILE` | Path to password file |

---

## Homeserver

The default homeserver is `https://matrix.aboutco.ai/` (running Dendrite 0.13.7 via Cloudflare tunnel).

You can use any Matrix homeserver:
- Self-hosted (Synapse, Dendrite, Conduit)
- Hosted providers (Element One, Beeper, etc.)
- Public servers (matrix.org, etc.)

---

## Security

### Credential Storage

**Never commit credentials to git!** Use one of these approaches:

1. **agenix/sops** (recommended for production)
   ```nix
   accessTokenFile = "/run/agenix/matrix-token";
   ```

2. **Plain files** (simpler for personal use)
   ```nix
   accessTokenFile = "~/.secrets/matrix-token";
   ```

### File Permissions

Ensure credential files have restrictive permissions:
```bash
chmod 600 ~/.secrets/matrix-token
```

---

## Troubleshooting

### Check Service Status

**macOS:**
```bash
launchctl print gui/$UID/com.steipete.openclaw.gateway | grep state
```

**Linux:**
```bash
systemctl --user status openclaw-gateway
```

### View Logs

**macOS:**
```bash
tail -f /tmp/openclaw/openclaw-gateway.log
```

**Linux:**
```bash
journalctl --user -u openclaw-gateway -f
```

### Common Issues

**Bot doesn't respond:**
- Check that the service is running
- Verify credentials are correct
- Check logs for authentication errors

**"Invalid access token":**
- Tokens can expire; generate a new one
- Ensure the file path is correct

**Can't connect to homeserver:**
- Verify the homeserver URL
- Check network connectivity
- Ensure the homeserver is not blocking your client

---

## Migration from Telegram

If you're migrating from Telegram to Matrix:

1. Create a Matrix account for your bot
2. Get an access token or set a password
3. Update your `flake.nix` to use `programs.openclaw.matrix` instead of Telegram config
4. Remove Telegram-specific configuration
5. Run `home-manager switch`

The bot will perform the bootstrap ritual again when you first message it on Matrix.

---

## Additional Resources

- [Openclaw Matrix Plugin Docs](https://docs.openclaw.ai/channels/matrix)
- [Matrix Client-Server API](https://spec.matrix.org/latest/client-server-api/)
- [nix-openclaw README](../README.md)

---

*For support, join the Openclaw Discord #golden-path-deployments channel.*
