#!/bin/sh
set -e
if [ -f package.json ]; then
  "$REMOVE_PACKAGE_MANAGER_FIELD_SH" package.json
fi

if [ -f src/logging.ts ]; then
  if ! grep -q "CLAWDBOT_LOG_DIR" src/logging.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/logging.ts")
if path.exists():
    text = path.read_text()
    old = 'export const DEFAULT_LOG_DIR = "/tmp/clawdbot";'
    new = 'export const DEFAULT_LOG_DIR = process.env.CLAWDBOT_LOG_DIR ?? "/tmp/clawdbot";'
    if old in text:
        path.write_text(text.replace(old, new))
PY
  fi
fi

if [ -f src/agents/shell-utils.ts ]; then
  if ! grep -q "envShell" src/agents/shell-utils.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/agents/shell-utils.ts")
if path.exists():
    text = path.read_text()
    if "existsSync" not in text:
        text = text.replace(
            'import { spawn } from "node:child_process";',
            'import { spawn } from "node:child_process";\nimport { existsSync } from "node:fs";',
        )
    old = '  const shell = process.env.SHELL?.trim() || "sh";\n  return { shell, args: ["-c"] };'
    new = (
        '  const envShell = process.env.SHELL?.trim();\n'
        '  const shell =\n'
        '    envShell && envShell.startsWith("/") && !existsSync(envShell)\n'
        '      ? "sh"\n'
        '      : envShell || "sh";\n'
        '  return { shell, args: ["-c"] };'
    )
    if old in text:
        path.write_text(text.replace(old, new))
PY
  fi
fi

if [ -f src/docker-setup.test.ts ]; then
  if ! grep -q "#!/bin/sh" src/docker-setup.test.ts; then
    python3 - <<'PY'
from pathlib import Path

path = Path("src/docker-setup.test.ts")
if path.exists():
    text = path.read_text()
    text = text.replace("#!/usr/bin/env bash", "#!/bin/sh")
    text = text.replace("set -euo pipefail", "set -eu")
    text = text.replace(
        'if [[ "${1:-}" == "compose" && "${2:-}" == "version" ]]; then',
        'if [ "${1:-}" = "compose" ] && [ "${2:-}" = "version" ]; then',
    )
    text = text.replace(
        'if [[ "${1:-}" == "build" ]]; then',
        'if [ "${1:-}" = "build" ]; then',
    )
    text = text.replace(
        'if [[ "${1:-}" == "compose" ]]; then',
        'if [ "${1:-}" = "compose" ]; then',
    )
    path.write_text(text)
PY
  fi
fi
