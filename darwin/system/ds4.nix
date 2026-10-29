# DwarfStar (antirez/ds4) local LLM, sized to this Mac's unified memory.
# memoryGiB comes from local-user.nix (scripts/generate-local-user.sh).
# Tiers follow https://github.com/antirez/ds4/blob/main/docs/METAL.md
{
  pkgs,
  lib,
  username,
  memoryGiB,
  ...
}:
let
  modelDir = "/Users/${username}/.local/share/ds4";

  profile =
    if memoryGiB >= 256 then
      {
        # DeepSeek V4 Flash Q4
        target = "ds4f-q4";
        flags = [
          "--ctx"
          "65536"
        ];
      }
    else if memoryGiB >= 96 then
      {
        # DeepSeek V4 Flash Q2, ~81 GiB resident
        target = "ds4f-q2";
        flags = [
          "--ctx"
          "32768"
        ];
      }
    else if memoryGiB >= 64 then
      {
        # Qwen3.8 Flash Next Q2, ~42 GiB resident, n-gram table read from SSD
        target = "qwen38-q2";
        flags = [
          "--ctx"
          "8192"
          "--prefill-chunk"
          "1024"
        ];
      }
    else
      null;

  ds4 = pkgs.callPackage ../packages/ds4 {
    defaultFlags = [
      "-m"
      ''"$HOME/.local/share/ds4/ds4flash.gguf"''
    ]
    ++ profile.flags;
  };
in
lib.mkIf (profile != null) {
  environment.systemPackages = [ ds4 ];

  # Fetch the model in the background; the downloader resumes partial files
  # and skips finished ones, so running at every login is cheap.
  launchd.user.agents.ds4-model-download.serviceConfig = {
    ProgramArguments = [
      "${ds4}/bin/ds4-download-model"
      profile.target
    ];
    EnvironmentVariables.DS4_ROOT = modelDir;
    RunAtLoad = true;
    ProcessType = "Background";
    LowPriorityIO = true;
    StandardOutPath = "/Users/${username}/Library/Logs/ds4-model-download.log";
    StandardErrorPath = "/Users/${username}/Library/Logs/ds4-model-download.log";
  };
}
