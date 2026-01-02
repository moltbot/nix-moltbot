{ lib
, stdenv
, fetchurl
, undmg
}:

stdenv.mkDerivation {
  pname = "clawdis-app";
  version = "2.0.0-beta4";

  src = fetchurl {
    url = "https://github.com/steipete/clawdis/releases/download/v2.0.0-beta4/Clawdis-2.0.0-beta4.dmg";
    hash = "sha256-h8YURO+ICEQWUpfQ2E2zwp8mgCKCA5njzhUEbXLovKc=";
  };

  nativeBuildInputs = [ undmg ];

  unpackPhase = ''
    undmg "$src"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    if [ -d "Clawdis.app" ]; then
      cp -R "Clawdis.app" "$out/Applications/Clawdis.app"
    else
      echo "Clawdis.app not found after undmg" >&2
      exit 1
    fi
    runHook postInstall
  '';

  meta = with lib; {
    description = "Clawdis macOS app bundle";
    homepage = "https://github.com/steipete/clawdis";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
