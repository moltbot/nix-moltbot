{ lib
, stdenvNoCC
, fetchzip
}:

stdenvNoCC.mkDerivation {
  pname = "openclaw-app";
  version = "2026.2.13";

  src = fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.2.13/OpenClaw-2026.2.13.zip";
    hash = "sha256-ewIZCQ3mg9dus3tD3BdUmESwsk1CFpClbJbLRT1g9Bc=";
    stripRoot = false;
  };

  dontUnpack = true;

  installPhase = "${../scripts/openclaw-app-install.sh}";

  meta = with lib; {
    description = "OpenClaw macOS app bundle";
    homepage = "https://github.com/openclaw/openclaw";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
