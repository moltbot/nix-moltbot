#!/bin/sh
set -e
mkdir -p "$out/Applications"
app_path="$(find "$src" -maxdepth 2 -name '*.app' -print -quit)"
if [ -z "$app_path" ]; then
  echo "Openclaw.app not found in $src" >&2
  exit 1
fi
cp -R "$app_path" "$out/Applications/Openclaw.app"
