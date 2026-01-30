#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: openclaw-reload [test|prod|both]

Re-render Openclaw config via Home Manager (no sudo) and restart gateway(s).

Defaults to: test
EOF
}

instance="${1:-test}"

case "$instance" in
  test) labels=("com.steipete.openclaw.gateway.nix-test") ;;
  prod) labels=("com.steipete.openclaw.gateway.nix") ;;
  both) labels=("com.steipete.openclaw.gateway.nix" "com.steipete.openclaw.gateway.nix-test") ;;
  -h|--help) usage; exit 0 ;;
  *) usage; exit 1 ;;
esac

if command -v hm-apply >/dev/null 2>&1; then
  hm-apply
elif [[ -n "${OPENCLAW_RELOAD_HM_CMD:-}" ]]; then
  eval "$OPENCLAW_RELOAD_HM_CMD"
else
  echo "[openclaw-reload] no Home Manager command available." >&2
  echo "[openclaw-reload] install hm-apply or set OPENCLAW_RELOAD_HM_CMD." >&2
  exit 1
fi

for label in "${labels[@]}"; do
  /bin/launchctl kickstart -k "gui/$UID/$label"
done
