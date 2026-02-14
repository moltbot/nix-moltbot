# Golden Paths

nix-openclaw is opinionated: **there should be one obvious way to deploy**.

A **Golden Path** is a supported topology + defaults + docs that:

- is secure by default
- is reproducible (pinned inputs)
- avoids manual state drift
- has a clear boundary between **Nix-managed config** and **runtime state**

If your setup doesn’t match a Golden Path, it may still work — but you’re on your own.

## GP1: Single Mac (laptop or Mac mini)

**Who it’s for:** simplest “it just works” install; macOS-only capabilities available locally.

- Gateway: macOS (launchd)
- OpenClaw.app: same machine
- Networking: localhost (default)

## GP2: VPS Gateway + Mac Node (recommended for reliability)

**Who it’s for:** always-on Gateway (Telegram/Discord/etc) with macOS-only capabilities bridged from your Mac.

- Gateway: Linux VPS (systemd user service)
- Node: OpenClaw.app on macOS (connects over WebSocket)
- Networking: **Tailscale tailnet** (private), no public exposure

Key idea: the Gateway routes tool calls to the node when `host=node` is selected.

### Why Tailscale?

- private-by-default connectivity
- MagicDNS stable hostnames (no IP chasing)
- easy to lock down with ACLs

### Nix mode on macOS app

OpenClaw.app supports **Nix mode** (`OPENCLAW_NIX_MODE=1` or `defaults write ai.openclaw.mac openclaw.nixMode -bool true`).

In Nix mode the app disables auto-mutation flows and treats config as read-only.
If something is missing for a fully declarative deployment, it’s a bug — fix it upstream.

## GP3: Laptop-only dev

**Who it’s for:** local experimentation.

- Gateway: macOS/Linux laptop
- Node: optional
- Expect downtime / sleep / network changes

## macOS permissions (TCC)

On unmanaged Macs, privacy permissions (Screen Recording, Accessibility, etc.) are not fully declarative.
You can check required permissions in `openclaw nodes status/describe` and then approve them once.

## Runtime state vs pinned config

Pinned / Nix-managed:
- `openclaw.json` (gateway config)
- documents (`AGENTS.md`, `SOUL.md`, `TOOLS.md`, etc.)
- workspace path selection

Runtime:
- sessions, caches
- pairing state (devices/nodes)
- exec approvals
