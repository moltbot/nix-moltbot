{ pkgs }:
let
  safe = list: builtins.filter (p: p != null) list;
  pick = name: if builtins.hasAttr name pkgs then pkgs.${name} else null;
  ensure = names: safe (map pick names);

  baseNames = [
    "nodejs_22"
    "pnpm_10"
    "git"
    "curl"
    "jq"
    "python3"
    "ffmpeg"
    "sox"
    "ripgrep"
  ];

  extendedNames = baseNames ++ [
    "go"
    "uv"
    "openai-whisper"
    "spotify-player"
    "gogcli"
    "peekaboo"
    "camsnap"
    "bird"
    "sag"
    "summarize"
    "gemini-cli"
    "openhue-cli"
    "wacli"
    "sonoscli"
    "imsg"
    "ordercli"
    "blucli"
    "eightctl"
    "mcporter"
    "oracle"
    "qmd"
    "nano-pdf"
  ];

in {
  base = ensure baseNames;
  extended = ensure extendedNames;
}
