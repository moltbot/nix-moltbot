{ lib
, buildEnv
, clawdis-gateway
, clawdis-app
, extendedTools
}:

buildEnv {
  name = "clawdis-2.0.0-beta5";
  paths = [ clawdis-gateway clawdis-app ] ++ extendedTools;
  pathsToLink = [ "/bin" "/Applications" ];

  meta = with lib; {
    description = "Clawdis batteries-included bundle (gateway + app + tools)";
    homepage = "https://github.com/steipete/clawdis";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
