#!/usr/bin/env bash
set -euo pipefail

link_agent() {
  local target="$1"
  local label="$2"

  local candidate
  local hm_gen
  hm_gen="$(realpath "$HOME/.local/state/nix/profiles/home-manager" 2>/dev/null || true)"
  if [ -n "$hm_gen" ] && [ -e "$hm_gen/LaunchAgents/${label}.plist" ]; then
    candidate="$hm_gen/LaunchAgents/${label}.plist"
  else
    candidate="$(/bin/ls -t /nix/store/*${label}.plist 2>/dev/null | /usr/bin/head -n 1 || true)"
  fi

  if [ -z "$candidate" ]; then
    return 0
  fi

  local current
  current="$(/usr/bin/readlink "$target" 2>/dev/null || true)"

  if [ "$current" != "$candidate" ]; then
    /bin/ln -sfn "$candidate" "$target"
    /bin/launchctl bootout "gui/$UID" "$target" 2>/dev/null || true
    /bin/launchctl bootstrap "gui/$UID" "$target" 2>/dev/null || true
  fi

  /bin/launchctl kickstart -k "gui/$UID/$label" 2>/dev/null || true
}

link_agent "$HOME/Library/LaunchAgents/com.steipete.openclaw.gateway.nix.plist" \
  "com.steipete.openclaw.gateway.nix"

link_agent "$HOME/Library/LaunchAgents/com.steipete.openclaw.gateway.nix-test.plist" \
  "com.steipete.openclaw.gateway.nix-test"

link_agent "$HOME/Library/LaunchAgents/com.steipete.openclaw.gateway.prod.plist" \
  "com.steipete.openclaw.gateway.prod"

link_agent "$HOME/Library/LaunchAgents/com.steipete.openclaw.gateway.test.plist" \
  "com.steipete.openclaw.gateway.test"
