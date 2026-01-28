{ lib
, stdenvNoCC
, writeShellScript
, instanceName ? "default"
, gatewayWrapper
, stateDir
, logPath
, gatewayPort ? 18789
, homeDir ? ""
, configPath ? ""
}:

# Creates a minimal .app bundle that runs the clawdbot gateway.
# This .app can be granted Full Disk Access in System Preferences,
# which is required for iMessage support (imsg needs to read Messages.db).
#
# The LaunchAgent runs this .app's executable directly, passing environment
# variables (CLAWDBOT_CONFIG_PATH, CLAWDBOT_STATE_DIR, etc.) and handling
# stdout/stderr logging.
#
# Usage: 
#   1. Build and install this .app to ~/Applications/
#   2. Grant FDA in System Settings > Privacy & Security > Full Disk Access
#   3. The LaunchAgent will run the app's executable with proper env vars

let
  appName = if instanceName == "default" 
    then "Clawdbot Gateway Runner" 
    else "Clawdbot Gateway Runner (${instanceName})";
  
  bundleId = if instanceName == "default"
    then "com.clawdbot.gateway-runner"
    else "com.clawdbot.gateway-runner.${instanceName}";

  # The actual script that runs inside the .app
  # Environment variables (CLAWDBOT_CONFIG_PATH, etc.) are set by the LaunchAgent
  # stdout/stderr are handled by the LaunchAgent's StandardOutPath/StandardErrorPath
  runnerScript = writeShellScript "clawdbot-gateway-runner" ''
    #!/bin/bash
    set -euo pipefail
    
    # The LaunchAgent sets these env vars, but provide fallbacks just in case
    export HOME="''${HOME:-${homeDir}}"
    export CLAWDBOT_CONFIG_PATH="''${CLAWDBOT_CONFIG_PATH:-${configPath}}"
    export CLAWDBOT_STATE_DIR="''${CLAWDBOT_STATE_DIR:-${stateDir}}"
    export CLAWDBOT_IMAGE_BACKEND="''${CLAWDBOT_IMAGE_BACKEND:-sips}"
    export CLAWDBOT_NIX_MODE="''${CLAWDBOT_NIX_MODE:-1}"
    
    # Run the gateway - stdout/stderr handled by LaunchAgent
    exec "${gatewayWrapper}/bin/clawdbot-gateway-${instanceName}" \
      gateway \
      --port ${toString gatewayPort}
  '';

  infoPlist = ''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>clawdbot-gateway-runner</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>${bundleId}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${appName}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>11.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
'';

in stdenvNoCC.mkDerivation {
  pname = "clawdbot-gateway-runner";
  version = "1.0.0";

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    APP_DIR="$out/Applications/${appName}.app"
    mkdir -p "$APP_DIR/Contents/MacOS"
    mkdir -p "$APP_DIR/Contents/Resources"

    # Write Info.plist
    cat > "$APP_DIR/Contents/Info.plist" << 'PLIST_EOF'
${infoPlist}
PLIST_EOF

    # Copy the runner script as the executable
    cp "${runnerScript}" "$APP_DIR/Contents/MacOS/clawdbot-gateway-runner"
    chmod +x "$APP_DIR/Contents/MacOS/clawdbot-gateway-runner"

    # Create PkgInfo
    echo -n "APPL????" > "$APP_DIR/Contents/PkgInfo"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Clawdbot Gateway Runner - minimal .app for FDA permissions";
    homepage = "https://github.com/clawdbot/clawdbot";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
