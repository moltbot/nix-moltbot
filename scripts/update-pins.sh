#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source_file="$repo_root/nix/sources/clawdbot-source.nix"
app_file="$repo_root/nix/packages/clawdbot-app.nix"

log() {
  printf '>> %s\n' "$*"
}

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but not installed." >&2
  exit 1
fi

log "Resolving clawdbot main SHA"
latest_sha=$(git ls-remote https://github.com/clawdbot/clawdbot.git refs/heads/main | awk '{print $1}' || true)
if [[ -z "$latest_sha" ]]; then
  echo "Failed to resolve clawdbot main SHA" >&2
  exit 1
fi
log "Latest clawdbot main: $latest_sha"

source_url="https://github.com/clawdbot/clawdbot/archive/${latest_sha}.tar.gz"
log "Prefetching source tarball"
source_prefetch=$(
  nix --extra-experimental-features "nix-command flakes" store prefetch-file --unpack --json "$source_url" 2>"/tmp/nix-prefetch-source.err" \
  || true
)
if [[ -z "$source_prefetch" ]]; then
  cat "/tmp/nix-prefetch-source.err" >&2 || true
  rm -f "/tmp/nix-prefetch-source.err"
  echo "Failed to resolve source hash" >&2
  exit 1
fi
rm -f "/tmp/nix-prefetch-source.err"
source_hash=$(printf '%s' "$source_prefetch" | jq -r '.hash // empty')
if [[ -z "$source_hash" ]]; then
  printf '%s\n' "$source_prefetch" >&2
  echo "Failed to parse source hash" >&2
  exit 1
fi
log "Source hash: $source_hash"

perl -0pi -e "s|rev = \"[^\"]+\";|rev = \"${latest_sha}\";|" "$source_file"
perl -0pi -e "s|hash = \"[^\"]+\";|hash = \"${source_hash}\";|" "$source_file"
# Force a fresh pnpmDepsHash recalculation for the new source rev.
perl -0pi -e "s|pnpmDepsHash = \"[^\"]*\";|pnpmDepsHash = \"\";|" "$source_file"

log "Fetching latest release metadata"
release_json=$(gh api /repos/clawdbot/clawdbot/releases?per_page=20 || true)
if [[ -z "$release_json" ]]; then
  echo "Failed to fetch release metadata" >&2
  exit 1
fi
release_tag=$(printf '%s' "$release_json" | jq -r '[.[] | select([.assets[]?.name | (test("^Clawdis-.*\\.zip$") and (test("dSYM") | not))] | any)][0].tag_name // empty')
if [[ -z "$release_tag" ]]; then
  echo "Failed to resolve a release tag with a Clawdis app asset" >&2
  exit 1
fi
log "Latest app release tag with asset: $release_tag"

app_url=$(printf '%s' "$release_json" | jq -r '[.[] | select([.assets[]?.name | (test("^Clawdis-.*\\.zip$") and (test("dSYM") | not))] | any)][0].assets[] | select(.name | (test("^Clawdis-.*\\.zip$") and (test("dSYM") | not))) | .browser_download_url' | head -n 1 || true)
if [[ -z "$app_url" ]]; then
  echo "Failed to resolve Clawdis app asset URL from latest release" >&2
  exit 1
fi
log "App asset URL: $app_url"

app_prefetch=$(
  nix --extra-experimental-features "nix-command flakes" store prefetch-file --unpack --json "$app_url" 2>"/tmp/nix-prefetch-app.err" \
  || true
)
if [[ -z "$app_prefetch" ]]; then
  cat "/tmp/nix-prefetch-app.err" >&2 || true
  rm -f "/tmp/nix-prefetch-app.err"
  echo "Failed to resolve app hash" >&2
  exit 1
fi
rm -f "/tmp/nix-prefetch-app.err"
app_hash=$(printf '%s' "$app_prefetch" | jq -r '.hash // empty')
if [[ -z "$app_hash" ]]; then
  printf '%s\n' "$app_prefetch" >&2
  echo "Failed to parse app hash" >&2
  exit 1
fi
log "App hash: $app_hash"

app_version="${release_tag#v}"
perl -0pi -e "s|version = \"[^\"]+\";|version = \"${app_version}\";|" "$app_file"
perl -0pi -e "s|url = \"[^\"]+\";|url = \"${app_url}\";|" "$app_file"
perl -0pi -e "s|hash = \"[^\"]+\";|hash = \"${app_hash}\";|" "$app_file"

build_log=$(mktemp)
log "Building gateway to validate pnpmDepsHash"
if ! nix build .#clawdbot-gateway --accept-flake-config >"$build_log" 2>&1; then
  pnpm_hash=$(grep -Eo 'got: *sha256-[A-Za-z0-9+/=]+' "$build_log" | head -n 1 | sed 's/.*got: *//' || true)
  if [[ -z "$pnpm_hash" ]]; then
    tail -n 200 "$build_log" >&2 || true
    rm -f "$build_log"
    exit 1
  fi
  log "pnpmDepsHash mismatch detected: $pnpm_hash"
  perl -0pi -e "s|pnpmDepsHash = \"[^\"]*\";|pnpmDepsHash = \"${pnpm_hash}\";|" "$source_file"
  if ! nix build .#clawdbot-gateway --accept-flake-config >"$build_log" 2>&1; then
    tail -n 200 "$build_log" >&2 || true
    rm -f "$build_log"
    exit 1
  fi
fi
rm -f "$build_log"

log "Building app to validate fetchzip hash"
nix build .#clawdbot-app --accept-flake-config

if git diff --quiet; then
  echo "No pin changes detected."
  exit 0
fi

log "Committing updated pins"
git add "$source_file" "$app_file"
git commit -F - <<'EOF'
🤖 codex: bump clawdbot pins (no-issue)

What:
- pin clawdbot source to latest upstream main
- refresh macOS app pin to latest release asset
- update source and app hashes

Why:
- keep nix-clawdbot on latest upstream for yolo mode

Tests:
- nix build .#clawdbot-gateway --accept-flake-config
- nix build .#clawdbot-app --accept-flake-config
EOF

git push origin HEAD:main
