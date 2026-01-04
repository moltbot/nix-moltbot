{ lib
, stdenvNoCC
, fetchzip
}:

stdenvNoCC.mkDerivation {
  pname = "clawdis-app";
  version = "2.0.0-beta4";

  src = fetchzip {
    url = "https://github.com/steipete/clawdis/releases/download/v2.0.0-beta4/Clawdis-2.0.0-beta4.zip";
    hash = "sha256-Oa7cejVFfZtJBSmjDaRjqocVyXo+WeS/xucGpJFDzIg=";
    stripRoot = false;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    app_path="$(find "$src" -maxdepth 2 -path "$src/__MACOSX" -prune -o -name 'Clawdis.app' -print -quit)"
    if [ -z "$app_path" ]; then
      echo "Clawdis.app not found in $src" >&2
      exit 1
    fi
    cp -R "$app_path" "$out/Applications/Clawdis.app"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Clawdis macOS app bundle";
    homepage = "https://github.com/steipete/clawdis";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
