{ username, ... }:
{
  # For video playback
  homebrew.casks = [
    "vlc"
  ];

  home-manager.users.${username}.fileAssociations.duti."org.videolan.vlc" = [
    "mkv"
    "mp4"
    "avi"
    "mp3"
    "mov"
    "wav"
    "flac"
    "ogg"
    "webm"
    "webp"
  ];
}
