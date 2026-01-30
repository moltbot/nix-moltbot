# RFC: Declarative Openclaw as a Nix Package (nix-openclaw)

- Date: 2026-01-02
- Status: Implementing
- Audience: Nix users, agents (Codex/Claude), package maintainers, operators

## 1) Narrative: what we are building and why

Openclaw is powerful but hard to install and configure for new users, especially those who do not want to learn Nix internals. We need a batteries‑included, obvious, and safe path to get a working Openclaw instance with minimal friction. This RFC proposes a dedicated public repo, `nix-openclaw`, that packages Openclaw for Nix and provides a declarative, user‑friendly configuration layer with strong defaults and an agent‑first onboarding flow.

The goal is a **fully declarative bootstrap**: users provide a small set of inputs (token path + allowlist), and the setup is deterministic and repeatable.

## 1.1) Non‑negotiables

- Nix‑first installation: no global installs, no manual brew steps required for core functionality.
- Safe defaults: providers disabled unless explicitly enabled and configured.
- No secrets committed to the repo; explicit guidance for secrets wiring (agenix‑style).
- Agent‑first docs: one path, deterministic steps, no guesswork.
- Deterministic builds and reproducible outputs.
- Documentation must be suitable for publication on the internet.

## 1.2) Scope boundaries (avoid confusion)

This RFC is only about:
- The public `nix-openclaw` repo (package + module + docs).
- A generic, end‑user Nix setup that lives outside any personal config repo.

This RFC is explicitly **not** about:
- Josh’s personal `nixos-config` or any private machine configuration.
- Editing or publishing personal settings, tokens, or machine‑specific modules.

## 2) Goals / Non‑goals

Goals:
- Provide a Nix package for Openclaw and a Home Manager module with batteries‑included defaults.
- Provide a macOS app bundle package aligned to the gateway version.
- Make configuration technically light with explicit options and guardrails.
- Telegram‑first configuration and defaults.
- Provide a single agent‑first onboarding flow that is end‑to‑end declarative.
- New user can get a working bot in 10 minutes without understanding Nix internals.

Non‑goals:
- Rewriting Openclaw core functionality.
- Supporting non‑Nix install paths in this repo.
- Shipping a hosted SaaS or paid hosting.
- Replacing upstream Openclaw docs.
- Cross‑platform support (Linux/Windows) in v1.
- CI automation in v1.

## 3) System overview

`nix-openclaw` is a public repo that provides (macOS‑only in v1, no CI in v1):
- A Nix package derivation for the Openclaw gateway.
- A Nix package for the macOS app bundle (DMG).
- A Home Manager module for user‑level config and service wiring.
- A nix‑darwin module for macOS users (optional, thin wrapper over HM).
- A flake with a batteries‑included default package.
- Agent‑first documentation and a declarative bootstrap flow.

## 4) Components and responsibilities

- **Package derivation**: builds Openclaw gateway from a pinned source.
- **App bundle**: installs Openclaw.app from a pinned DMG matching the gateway version.
- **Home Manager module**: declarative config, writes `~/.openclaw/openclaw.json`, manages services.
- **Flake outputs**:
  - `packages.<system>.openclaw` (default batteries‑included bundle)
  - `packages.<system>.openclaw-gateway`
  - `packages.<system>.openclaw-app`
  - `packages.<system>.openclaw-tools`
  - `homeManagerModules.openclaw`
  - `darwinModules.openclaw` (if needed)

## 5) Configuration model (public contract)

The Home Manager module is the public contract. It must expose a small, explicit option set (enable, token path, allowlist) and render a deterministic `~/.openclaw/openclaw.json`.

The design constraint: users should not have to write arbitrary JSON. The module is the supported configuration surface for v1.

## 6) Agent‑first onboarding flow (single source of truth)

The README is the only supported onboarding path. It must include:
- Human vs agent split
- Minimal config snippet
- Deterministic steps and stop conditions
- Verification steps and expected success signals

## 7) Secrets handling (opinionated default)

- Recommend agenix for bot tokens on macOS.
- Default docs refer to a token file path under `/run/agenix/`.

## 8) Backing tools (batteries‑included)

- Base and extended toolchains are installed via Nix by default.
- Tools correspond to upstream Openclaw skill installers (brew/go/node/uv) mapped into nixpkgs where possible.

## 9) Compatibility guarantees

- Gateway and macOS app versions are pinned to the same release tag.
- Launchd label and log paths are aligned with the macOS app defaults.
- App is forced into attach‑only mode to prevent it from spawning its own gateway.

## 10) Prod vs dev split (planned)

We will maintain two distinct setups:

- **Prod (stable)**
  - Uses `nix-openclaw` batteries‑included package.
  - Pinned to released tags.
  - No source builds.
  - Launchd managed by Nix.
  - App attaches to Nix gateway only.

- **Dev (experimental)**
  - Uses local source checkout (macOS app + gateway).
  - Separate launchd label and state/log paths to avoid collisions.
  - Free to change versions, flags, and test features.

No changes to personal `nixos-config` are made in this repo; this is a plan only.

## 11) Definition of Done (DoD)

This RFC is complete when:
- The repo is public with a clear README and agent‑first guide.
- Telegram‑first quickstart works on macOS with a real bot token.
- `nix run .#openclaw` installs gateway + app + tools.
- Launchd uses `com.steipete.openclaw.gateway` and logs to `/tmp/openclaw/openclaw-gateway.log`.
- App runs in attach‑only mode (does not spawn its own gateway).
- Smoke test: user sends a Telegram message in an allowlisted chat and receives a response.

## 12) Implementation status (current)

- Gateway pinned to `v2.0.0-beta4`.
- App DMG pinned to `v2.0.0-beta4`.
- Batteries‑included package output is wired in the flake.
- README is the single onboarding source.
