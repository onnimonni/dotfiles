{ ...}:
{
  system.defaults.CustomUserPreferences."com.apple.symbolichotkeys" = {
    # Well I have absolutely no idea what all of these do
    # I copied them from:
    # $ defaults read com.apple.symbolichotkeys
    # And at least I have changed ⌥ + TAB -> alter windows of same program
    AppleSymbolicHotKeys = {
      "164" = {
        enabled = 0;
        value = {
          parameters = [65535 65535 0];
          type = "standard";
        };
      };
      "176" = {
          enabled = 0;
          value = {
            type = "SAE1.0";
          };
      };
      "27" = {
          enabled = 1;
          value = {
              parameters = [65535 48 524288];
              type = "standard";
          };
      };
      "52" = {
          enabled = 0;
          value = {
            parameters = [100 2 1572864];
            type = "standard";
          };
      };
      "60" = {
          enabled = 1;
          value = {
            parameters = [32 49 262144];
            type = "standard";
          };
      };
      "61" = {
          enabled = 1;
          value = {
            parameters = [32 49 786432];
            type = "standard";
          };
      };
      "65" = {
          enabled = 0;
          value = {
            parameters = [32 49 1572864];
            type = "standard";
          };
      };
    };
  };
}
