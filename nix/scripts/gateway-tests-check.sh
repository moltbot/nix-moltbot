#!/bin/sh
set -e

store_path_file="${PNPM_STORE_PATH_FILE:-.pnpm-store-path}"
if [ -f "$store_path_file" ]; then
  store_path="$(cat "$store_path_file")"
  export PNPM_STORE_DIR="$store_path"
  export PNPM_STORE_PATH="$store_path"
  export NPM_CONFIG_STORE_DIR="$store_path"
  export NPM_CONFIG_STORE_PATH="$store_path"
fi
export HOME="$(mktemp -d)"
export TMPDIR="${HOME}/tmp"
mkdir -p "$TMPDIR"
export OPENCLAW_LOG_DIR="${TMPDIR}/openclaw-logs"
export MOLTBOT_LOG_PATH="${OPENCLAW_LOG_DIR}/openclaw-gateway.log"
mkdir -p "$OPENCLAW_LOG_DIR"
mkdir -p /tmp/openclaw || true
chmod 700 /tmp/openclaw || true
export VITEST_POOL="threads"
export VITEST_MIN_THREADS="2"
export VITEST_MAX_THREADS="2"
export VITEST_MIN_WORKERS="2"
export VITEST_MAX_WORKERS="2"

pnpm vitest run --config vitest.gateway.config.ts --testTimeout=20000
