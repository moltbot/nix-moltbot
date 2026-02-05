#!/bin/sh
set -e
mkdir -p "$out/lib/openclaw" "$out/bin"

cp -r dist node_modules package.json ui "$out/lib/openclaw/"
if [ -d extensions ]; then
  cp -r extensions "$out/lib/openclaw/"
fi

if [ -d docs/reference/templates ]; then
  mkdir -p "$out/lib/openclaw/docs/reference"
  cp -r docs/reference/templates "$out/lib/openclaw/docs/reference/"
fi

if [ -z "${STDENV_SETUP:-}" ]; then
  echo "STDENV_SETUP is not set" >&2
  exit 1
fi
if [ ! -f "$STDENV_SETUP" ]; then
  echo "STDENV_SETUP not found: $STDENV_SETUP" >&2
  exit 1
fi

bash -e -c '. "$STDENV_SETUP"; patchShebangs "$out/lib/openclaw/node_modules/.bin"'
if [ -d "$out/lib/openclaw/ui/node_modules/.bin" ]; then
  bash -e -c '. "$STDENV_SETUP"; patchShebangs "$out/lib/openclaw/ui/node_modules/.bin"'
fi
# Patch shebangs in extensions node_modules if present
if [ -d "$out/lib/openclaw/extensions" ]; then
  for ext_bin in "$out/lib/openclaw/extensions"/*/node_modules/.bin; do
    if [ -d "$ext_bin" ]; then
      bash -e -c '. "$STDENV_SETUP"; patchShebangs "'"$ext_bin"'"'
    fi
  done
fi

# Work around missing dependency declaration in pi-coding-agent (strip-ansi).
# Ensure it is resolvable at runtime without changing upstream.
pi_pkg="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/node_modules/@mariozechner/pi-coding-agent" -print | head -n 1)"
strip_ansi_src="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/node_modules/strip-ansi" -print | head -n 1)"

if [ -n "$strip_ansi_src" ]; then
  if [ -n "$pi_pkg" ] && [ ! -e "$pi_pkg/node_modules/strip-ansi" ]; then
    mkdir -p "$pi_pkg/node_modules"
    ln -s "$strip_ansi_src" "$pi_pkg/node_modules/strip-ansi"
  fi

  if [ ! -e "$out/lib/openclaw/node_modules/strip-ansi" ]; then
    mkdir -p "$out/lib/openclaw/node_modules"
    ln -s "$strip_ansi_src" "$out/lib/openclaw/node_modules/strip-ansi"
  fi
fi

if [ -n "${PATCH_CLIPBOARD_SH:-}" ]; then
  "$PATCH_CLIPBOARD_SH" "$out/lib/openclaw" "$PATCH_CLIPBOARD_WRAPPER"
fi

# Work around missing combined-stream dependency for form-data in pnpm layout.
combined_stream_src="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/combined-stream@*/node_modules/combined-stream" -print | head -n 1)"
form_data_pkgs="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/node_modules/form-data" -print)"
if [ -n "$combined_stream_src" ]; then
  if [ ! -e "$out/lib/openclaw/node_modules/combined-stream" ]; then
    ln -s "$combined_stream_src" "$out/lib/openclaw/node_modules/combined-stream"
  fi
  if [ -n "$form_data_pkgs" ]; then
    for pkg in $form_data_pkgs; do
      if [ ! -e "$pkg/node_modules/combined-stream" ]; then
        mkdir -p "$pkg/node_modules"
        ln -s "$combined_stream_src" "$pkg/node_modules/combined-stream"
      fi
    done
  fi
fi

# Work around missing hasown dependency for form-data in pnpm layout.
hasown_src="$(find "$out/lib/openclaw/node_modules/.pnpm" -path "*/hasown@*/node_modules/hasown" -print | head -n 1)"
if [ -n "$hasown_src" ]; then
  if [ ! -e "$out/lib/openclaw/node_modules/hasown" ]; then
    ln -s "$hasown_src" "$out/lib/openclaw/node_modules/hasown"
  fi
  if [ -n "$form_data_pkgs" ]; then
    for pkg in $form_data_pkgs; do
      if [ ! -e "$pkg/node_modules/hasown" ]; then
        mkdir -p "$pkg/node_modules"
        ln -s "$hasown_src" "$pkg/node_modules/hasown"
      fi
    done
  fi
fi

bash -e -c '. "$STDENV_SETUP"; makeWrapper "$NODE_BIN" "$out/bin/openclaw" --add-flags "$out/lib/openclaw/dist/index.js" --set-default OPENCLAW_NIX_MODE "1" --set-default MOLTBOT_NIX_MODE "1" --set-default CLAWDBOT_NIX_MODE "1"'
ln -s "$out/bin/openclaw" "$out/bin/moltbot"
