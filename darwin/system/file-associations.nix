{ pkgs, lib, ... }:
{
  home.packages = [
    pkgs.duti
  ];

  # Create a home activation script to apply duti settings
  home.activation = {
    setFileAssociation = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "Setting file associations with duti..."
      ${pkgs.duti}/bin/duti ~/.duti.conf
    '';
  };

  home.file = {
    ".duti.conf".text = ''
      # Open links in Finicky
      net.kassett.finicky http
      net.kassett.finicky https
      net.kassett.finicky com.apple.default-app.web-browser all

      # VLC
      org.videolan.vlc mkv all
      org.videolan.vlc mp4 all
      org.videolan.vlc avi all
      org.videolan.vlc mp3 all
      org.videolan.vlc mov all
      org.videolan.vlc wav all
      org.videolan.vlc flac all
      org.videolan.vlc ogg all
      org.videolan.vlc webm all
      org.videolan.vlc webp all

      # VS Code
      com.microsoft.VSCode public.source-code	all
      com.microsoft.VSCode public.plain-text all
      com.microsoft.VSCode .xml all
      com.microsoft.VSCode .md all
    '';
  };
}
