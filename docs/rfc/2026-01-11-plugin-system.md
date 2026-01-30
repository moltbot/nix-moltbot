# RFC: Openclaw Plugin System — The Golden Path

- Date: 2026-01-11
- Status: Draft
- Audience: Peter (openclaw maintainer), nix-openclaw maintainers

## Goals

**Peter's goals:** Easy extension, maintainable core, thriving ecosystem, ship fast.

**Our goals:** Properly bundled tools with reproducible builds, single-install experience, it Just Works.

**This RFC argues:** The nix-openclaw plugin model achieves both. It should become the golden path for extending openclaw.

---

## The Problem with Core Bloat

Voice-call landed in core (+8K LOC). It works, but:
- Core now has Twilio/Telnyx deps even if you don't use voice-call
- Changes to voice-call require openclaw releases
- Testing voice-call means testing all of openclaw
- Contributors need to understand the whole codebase

This pattern doesn't scale. Every new capability bloats core.

## The Problem with Skills-Only

Skills are great for teaching the agent, but they're not enough:
- A skill says "use the `voicecall` CLI" — but where does the CLI come from?
- A skill says "set TWILIO_ACCOUNT_SID" — but what validates it's set?
- A skill describes commands — but what installs the binary?

Skills without tools are hallucinations waiting to happen.

---

## The nix-openclaw Model: Bundle Everything

A plugin is **just a GitHub repo** that self-declares its contract:

```
plugin/
├── flake.nix          # Build system + plugin contract
├── src/               # Tool source code
├── skills/            # Teaching docs for the agent
└── config/            # Default settings, schemas
```

That's it. No registry. No central authority. Point at a repo, get a plugin.

One install gives you:
- **Binary** on PATH (built from source, pinned version)
- **Skills** in workspace (agent knows how to use it)
- **Config** validated (missing env = install fails, not runtime error)
- **State dirs** created (plugin has a home)

**Everything updates in sync.** When upstream pushes changes — new CLI flags, updated skill docs, schema tweaks — you pull the new version and everything updates together. No "skill says X but binary doesn't support it" drift. No manual coordination. Just works.

### Real Example: xuezh (Chinese learning)

```nix
openclawPlugin = {
  name = "xuezh";
  skills = [ ./skills/xuezh ];
  packages = [ self.packages.${system}.default ];
  needs = {
    stateDirs = [ ".config/xuezh" ];
    requiredEnv = [
      "XUEZH_AZURE_SPEECH_KEY_FILE"
      "XUEZH_AZURE_SPEECH_REGION"
    ];
  };
};
```

**What happens on install:**
1. `xuezh` binary built from Go source, added to PATH
2. 400-line skill symlinked to workspace — teaches agent pedagogy, CLI patterns, grading rubrics
3. `~/.config/xuezh/` created
4. Install **fails** if Azure env vars aren't wired up

**Result:** User wires up secrets once. Plugin Just Works. Agent knows how to teach Chinese.

### Real Example: gohome (home automation)

```nix
openclawPlugin = {
  name = "gohome";
  skills = [ ./skills/gohome ];
  packages = [ self.packages.${system}.default ];
  needs = {
    stateDirs = [];
    requiredEnv = [];
  };
};
```

No secrets — uses Tailscale MagicDNS. CLI talks to a background gRPC server.

Skill teaches the agent:
```markdown
## Friendly CLI
gohome-cli roborock status
gohome-cli roborock clean kitchen
gohome-cli tado set living-room 20

## Sending maps to users
MEDIA:http://gohome:8080/roborock/map.png?labels=names
```

**Result:** Install plugin, agent can control your home. No manual binary install, no forgetting to set env vars.

### Real Example: padel (court booking)

```nix
openclawPlugin = {
  name = "padel";
  skills = [ ./skills/padel ];
  packages = [ self.packages.${system}.default ];
  needs = {
    stateDirs = [ ".config/padel" ];
    requiredEnv = [ "PADEL_AUTH_FILE" ];
  };
};
```

Skill teaches CLI + booking authorization logic + personality ("respond in exaggerated Trump manner").

**Result:** Wire up Playtomic auth, agent can book padel courts. Complete workflow in one plugin.

---

## Why This Model is Better

### vs. Skills-Only

| Aspect | Skills-only | Bundled plugin |
|--------|-------------|----------------|
| Binary | Hope user installed it | Built + installed automatically |
| Config | Hope user set env vars | Validated at install time |
| Version | Whatever's on PATH | Pinned to exact commit |
| Rollback | Manual | Instant (previous generation) |
| Dependencies | User's problem | Bundled in build |

Skills-only is "here's how to use a tool that may or may not exist."
Bundled plugin is "here's the tool, its docs, and everything it needs."

### vs. Core Integration

| Aspect | In core | Plugin |
|--------|---------|--------|
| Core LOC | +8K per feature | Zero |
| Dependencies | Everyone gets them | Only if you install |
| Release cycle | Tied to openclaw | Independent |
| Testing | Test everything | Test plugin only |
| Contributor barrier | Understand whole codebase | Understand plugin only |

Core should be transports + agent loop. Capabilities belong in plugins.

### What About TypeBox Schemas?

Peter's voice-call has TypeBox tool schemas — validated params, type safety.

Our model uses skill prose instead. Trade-off:

| Aspect | TypeBox schema | Skill prose |
|--------|---------------|-------------|
| Validation | Gateway validates params | Agent follows instructions |
| Type safety | Compile-time | None (string in/out) |
| Flexibility | Fixed schema | Agent can improvise |
| Works today | Needs gateway changes | Yes |

**Our take:** Skill prose is good enough for v1. Agent follows instructions reliably. If we need stricter validation later, skills can include JSON schemas that gateway parses.

### What About Subprocess Overhead?

CLI plugins spawn a process per call. Gateway plugins don't.

**Our take:** Subprocess overhead is negligible for most use cases. Voice-call might want tighter integration for latency — that's a v2 optimization, not a v1 blocker.

### What About Real-Time Webhooks?

Voice-call needs webhook handling for Twilio callbacks.

**Our take:** Same pattern as gohome — plugin runs a background server, CLI talks to it. Agent doesn't know or care about the server. Works today with the gohome model:

```
voicecall expose --mode funnel    # Start webhook server
voicecall init --to +1... --message "..."  # Agent calls CLI
voicecall status --call-id abc123  # Check for responses
```

---

## The Proposal: Make This the Golden Path

### What openclaw core should do

1. **Document the plugin contract** — `plugin.json` manifest schema (name, skills, bin, needs)
2. **Add discovery** — scan `~/.openclaw/extensions/` at startup
3. **Validate env** — fail fast if `requiredEnv` missing
4. **Create state dirs** — from manifest
5. **Add `openclaw plugins` CLI** — list, enable, disable, info

That's it. No dynamic code loading, no TypeBox registration, no RPC handlers. Just: find plugins, validate their needs, put binaries on PATH, copy skills to workspace.

### How nix-openclaw fits in

nix-openclaw is a **plugin installer** that wires plugins into openclaw's plugin system:

```nix
# User's flake.nix
programs.openclaw.plugins = [
  # Remote: point at GitHub repo
  { source = "github:joshp123/xuezh"; }
  { source = "github:joshp123/padel-cli"; }

  # Local dev: point at directory
  { source = "path:/Users/josh/code/my-plugin"; }
];

# Or enable first-party plugins (pinned in nix-openclaw):
programs.openclaw.firstParty.summarize.enable = true;
programs.openclaw.firstParty.oracle.enable = true;
```

**Same contract, multiple sources:**
- `github:owner/repo` — pull from GitHub, pin to commit
- `path:/local/dir` — local checkout for dev iteration
- First-party toggles — curated plugins pinned in nix-openclaw

At activation time, nix-openclaw:
1. Resolves flake sources (remote or local) → builds binaries
2. Validates `requiredEnv` (fails if missing)
3. Creates state dirs
4. Installs plugins to `~/.openclaw/extensions/<plugin>/`
5. Writes `plugin.json` manifest for each
6. Symlinks skills to workspace
7. Adds binaries to PATH

**openclaw core sees all plugins** — it scans `~/.openclaw/extensions/`, reads manifests, knows what's installed. The difference is nix-openclaw does the install + validation at build time (deterministic, fail-fast), while non-Nix users do it manually or via npm.

**Same plugin system, different installers:**
- Nix users: nix-openclaw installs plugins declaratively
- Non-Nix users: `openclaw plugins install` or manual setup
- openclaw core: sees the same `~/.openclaw/extensions/` structure either way

**Local dev workflow:** Point at a local path, change code, rebuild, gateway picks up changes. No push/pull cycle. Same contract, local iteration. For non-Nix: symlink your plugin dir into `~/.openclaw/extensions/`.

### What nix-openclaw provides (golden path)

- **Reproducible builds** — binary built from source, same everywhere
- **Version pinning** — plugin source locked to exact commit
- **Instant rollback** — switch to previous generation
- **Declarative config** — plugins + secrets in one flake
- **Atomic updates** — CLI + skill + config update together

### What npm provides (fallback)

- `openclaw plugins install @openclaw/voice-call` — npm install to extensions dir
- Manual env var setup
- Manual version management
- No reproducibility guarantees

It works. It's just not as good. (They should use Nix.)

---

## Voice-Call as a Plugin

The screenshot shows the interface:

```
voicecall init --to +1... --mode conversation --message "..."
voicecall continue --call-id ... --message "..."
voicecall expose --mode funnel|serve|off
```

As a plugin:

```nix
openclawPlugin = {
  name = "voice-call";
  skills = [ ./skills/voice-call ];
  packages = [ self.packages.${system}.default ];
  needs = {
    stateDirs = [ ".config/openclaw-voice-call" ];
    requiredEnv = [ "TWILIO_ACCOUNT_SID" "TWILIO_AUTH_TOKEN" ];
  };
};
```

Install wires up Twilio creds. Binary handles webhook server. Skill teaches agent the CLI. Done.

**Migration path:**
1. Create `@openclaw/voice-call` repo
2. Move code from core
3. Add plugin contract
4. Remove from core
5. Add to first-party plugins list

---

## The Plugin Ecosystem Vision

**First-party plugins** already exist — see [nix-steipete-tools](https://github.com/openclaw/nix-steipete-tools/tree/main/tools):
- `summarize` — YouTube/article summarization
- `oracle` — second-model review
- `peekaboo` — screenshot capture
- `camsnap` — webcam capture
- `poltergeist` — browser automation
- `sag` — web search
- `bird` — Twitter/X integration
- `sonoscli` — Sonos control
- `imsg` — iMessage integration
- `gogcli` — Google Calendar

All follow the same contract. All pinned in nix-openclaw. Enable with one line:
```nix
programs.openclaw.firstParty.summarize.enable = true;
```

**Community plugins** (anyone can ship):
- Just a GitHub repo with `flake.nix` + `openclawPlugin`
- No registry, no approval process
- User points at repo, wires secrets, it works

**Core stays lean:**
- Transports (Telegram, Discord, Slack)
- Agent loop
- Plugin discovery (for non-Nix users)
- That's it

---

## Summary

| What | How |
|------|-----|
| **Plugin = bundle** | Binary + skills + config + declared needs |
| **Install = it works** | Wire secrets once, everything validated |
| **Core = minimal** | Transports + agent + plugin loader |
| **Golden path = Nix** | Reproducible, pinned, instant rollback |
| **Fallback = npm** | Works, less guarantees |

**The pitch to Peter:**

Your voice-call is great. But it shouldn't live in core forever. The nix-openclaw plugin model lets you:
- Ship it independently (faster iteration)
- Keep core lean (easier maintenance)
- Let community extend openclaw (ecosystem growth)
- Guarantee it works when installed (fail-fast validation)

All you need to add to core is plugin discovery + env validation. We already have the contract, the tooling, and real plugins in production.

---

## Open Questions

1. **Manifest format:**
   - Nix users: `openclawPlugin` in `flake.nix` (already works)
   - Non-Nix users: `plugin.json` in plugin directory
   - **Suggested:** openclaw core defines `plugin.json` schema. Same fields as `openclawPlugin`:
     ```json
     {
       "name": "voice-call",
       "skills": ["./skills/voice-call"],
       "bin": { "voicecall": "./bin/voicecall" },
       "needs": {
         "stateDirs": [".config/openclaw-voice-call"],
         "requiredEnv": ["TWILIO_ACCOUNT_SID", "TWILIO_AUTH_TOKEN"]
       }
     }
     ```

2. **Discovery paths:**
   - **Suggested:** `~/.openclaw/extensions/<plugin>/` for user-installed, `.openclaw/extensions/<plugin>/` for project-local
   - openclaw core scans both paths at startup
   - nix-openclaw installs to the same paths — same structure, different installer

3. **First-party plugins for non-Nix:**
   - **Suggested:** `@openclaw/` npm scope, but don't invest heavily. Point people to Nix.

4. **Voice-call extraction:** Want to do this now, or later?

---

## Appendix: The Pattern

```
┌─────────────┐     shells out     ┌─────────────┐
│    Agent    │ ─────────────────► │  CLI binary │
└─────────────┘                    └──────┬──────┘
                                          │
                                          ▼
                                   ┌─────────────┐
                                   │   Backend   │
                                   │  (API/DB/   │
                                   │   server)   │
                                   └─────────────┘
```

- **padel:** CLI → Playtomic API
- **xuezh:** CLI → SQLite + Azure Speech
- **gohome:** CLI → gRPC server → devices
- **voice-call:** CLI → webhook server → Twilio

Agent never talks to backend directly. CLI is the interface. Skill teaches the agent. Plugin bundles everything.

This is the golden path.
