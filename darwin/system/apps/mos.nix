{ ... }:
{
  # Smooth scrolling for external mice — needed with UHK keyboard or
  # traditional scroll wheel mice, otherwise Safari scrolling feels broken
  homebrew.casks = [
    "mos@beta"
  ];

  system.defaults.CustomUserPreferences."com.caldis.Mos" = {
    hideStatusItem = true;
    updateCheckOnAppStart = true;
  };
}
