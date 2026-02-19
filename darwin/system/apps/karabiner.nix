# Declarative Karabiner-Elements config, generates ~/.config/karabiner/karabiner.json.
#
# HACK: Uses system.activationScripts.postActivation instead of home.file because
# Karabiner creates ~/.config/karabiner/ as a real directory (not a symlink), and
# home-manager can't replace a pre-existing directory with a managed symlink.
# The postActivation script writes JSON inline via heredoc on each darwin-rebuild.
#
# NOTE: nix-darwin only runs activation scripts named preActivation, postActivation,
# or extraActivation. Custom names (e.g. "configureKarabiner") are silently ignored.
{ username, ... }:
let
  scrollerBinPath = "/run/current-system/sw/bin/smooth-scroller";

  # Bundle IDs of apps that should get native Page Up/Down instead of smooth scroll.
  # Add apps here where scroll events don't work (e.g. terminal emulators, PDF viewers).
  pageUpDownBundleIds = [
    # "com.googlecode.iterm2"
  ];

  pageUpDownFallbackRule =
    if pageUpDownBundleIds == [ ] then
      [ ]
    else
      [
        {
          description = "fn+{u,o} → page up/down for non-scrollable apps";
          manipulators = map (m: m // { type = "basic"; }) [
            {
              conditions = [
                {
                  type = "frontmost_application_if";
                  bundle_identifiers = pageUpDownBundleIds;
                }
              ];
              from = {
                key_code = "u";
                modifiers = {
                  mandatory = [ "fn" ];
                  optional = [ "any" ];
                };
              };
              to = [ { key_code = "page_up"; } ];
            }
            {
              conditions = [
                {
                  type = "frontmost_application_if";
                  bundle_identifiers = pageUpDownBundleIds;
                }
              ];
              from = {
                key_code = "o";
                modifiers = {
                  mandatory = [ "fn" ];
                  optional = [ "any" ];
                };
              };
              to = [ { key_code = "page_down"; } ];
            }
          ];
        }
      ];

  # fn+u/o alone → smooth scroll (no optional modifiers, so fn+ctrl+u etc. won't match)
  smoothScrollRule = [
    {
      description = "fn+{u,o} → smooth scroll up/down";
      manipulators = map (m: m // { type = "basic"; }) [
        {
          from = {
            key_code = "u";
            modifiers.mandatory = [ "fn" ];
          };
          to = [ { shell_command = "${scrollerBinPath} start up"; } ];
          to_after_key_up = [ { shell_command = "${scrollerBinPath} stop"; } ];
        }
        {
          from = {
            key_code = "o";
            modifiers.mandatory = [ "fn" ];
          };
          to = [ { shell_command = "${scrollerBinPath} start down"; } ];
          to_after_key_up = [ { shell_command = "${scrollerBinPath} stop"; } ];
        }
      ];
    }
  ];

  # fn+u/o with any extra modifiers → native page up/down (catches fn+ctrl+cmd+u etc.)
  pageUpDownWithModifiersRule = [
    {
      description = "fn+modifier+{u,o} → page up/down";
      manipulators = map (m: m // { type = "basic"; }) [
        {
          from = {
            key_code = "u";
            modifiers = {
              mandatory = [ "fn" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "page_up"; } ];
        }
        {
          from = {
            key_code = "o";
            modifiers = {
              mandatory = [ "fn" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "page_down"; } ];
        }
      ];
    }
  ];

  # Karabiner rules are matched top-to-bottom, first match wins.
  # More specific rules (with more mandatory modifiers) must come before generic ones.
  rules = [
    {
      # HACK: macOS window tiling "Bottom Left"/"Bottom Right" need unique shortcuts that
      # don't conflict with per-app bindings (e.g. Ctrl+Cmd+End conflicts with Notes.app).
      # Solution: Karabiner remaps fn+ctrl+cmd+{m,.} to Ctrl+Cmd+{F19,F20} (unused virtual
      # keys in Unicode Private Use Area), which NSUserKeyEquivalents binds to tiling actions.
      # See keyboard.nix for the NSUserKeyEquivalents side.
      description = "Change fn+ctrl+cmd+{m,period} to ctrl+cmd+F19/F20 (window tiling)";
      manipulators = [
        {
          from = {
            key_code = "m";
            modifiers = {
              mandatory = [
                "fn"
                "control"
                "command"
              ];
            };
          };
          to = [
            {
              key_code = "f19";
              modifiers = [
                "control"
                "command"
              ];
            }
          ];
          type = "basic";
        }
        {
          from = {
            key_code = "period";
            modifiers = {
              mandatory = [
                "fn"
                "control"
                "command"
              ];
            };
          };
          to = [
            {
              key_code = "f20";
              modifiers = [
                "control"
                "command"
              ];
            }
          ];
          type = "basic";
        }
      ];
    }
    {
      description = "Change fn+hjkl to arrow keys";
      manipulators = map (m: m // { type = "basic"; }) [
        {
          from = {
            key_code = "j";
            modifiers = {
              mandatory = [ "fn" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "left_arrow"; } ];
        }
        {
          from = {
            key_code = "k";
            modifiers = {
              mandatory = [ "fn" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "down_arrow"; } ];
        }
        {
          from = {
            key_code = "i";
            modifiers = {
              mandatory = [ "fn" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "up_arrow"; } ];
        }
        {
          from = {
            key_code = "l";
            modifiers = {
              mandatory = [ "fn" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "right_arrow"; } ];
        }
      ];
    }
  ]
  ++ pageUpDownFallbackRule
  ++ smoothScrollRule
  ++ pageUpDownWithModifiersRule
  ++ [
    {
      description = "Change fn+{m,period} to home/end";
      manipulators = map (m: m // { type = "basic"; }) [
        {
          from = {
            key_code = "m";
            modifiers = {
              mandatory = [ "fn" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "home"; } ];
        }
        {
          from = {
            key_code = "period";
            modifiers = {
              mandatory = [ "fn" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "end"; } ];
        }
      ];
    }
    {
      description = "Change fn+, to enter";
      manipulators = [
        {
          from = {
            key_code = "comma";
            modifiers = {
              mandatory = [ "fn" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "return_or_enter"; } ];
          type = "basic";
        }
      ];
    }
    {
      description = "Change fn+awsd to arrow keys";
      manipulators = map (m: m // { type = "basic"; }) [
        {
          from = {
            key_code = "a";
            modifiers = {
              mandatory = [ "fn" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "left_arrow"; } ];
        }
        {
          from = {
            key_code = "s";
            modifiers = {
              mandatory = [ "fn" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "down_arrow"; } ];
        }
        {
          from = {
            key_code = "w";
            modifiers = {
              mandatory = [ "fn" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "up_arrow"; } ];
        }
        {
          from = {
            key_code = "d";
            modifiers = {
              mandatory = [ "fn" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "right_arrow"; } ];
        }
      ];
    }
    {
      description = "Change spacebar + homerow = numbers";
      manipulators = map (m: m // { type = "basic"; }) [
        {
          description = "Spacebar + A = 1";
          from = {
            key_code = "a";
            modifiers.mandatory = [ "right_shift" ];
          };
          to = [ { key_code = "1"; } ];
        }
        {
          description = "Spacebar + S = 2";
          from = {
            key_code = "s";
            modifiers.mandatory = [ "right_shift" ];
          };
          to = [ { key_code = "2"; } ];
        }
        {
          description = "Spacebar + D = 3";
          from = {
            key_code = "d";
            modifiers.mandatory = [ "right_shift" ];
          };
          to = [ { key_code = "3"; } ];
        }
        {
          description = "Spacebar + F = 4";
          from = {
            key_code = "f";
            modifiers.mandatory = [ "right_shift" ];
          };
          to = [ { key_code = "4"; } ];
        }
        {
          description = "Spacebar + G = 5";
          from = {
            key_code = "g";
            modifiers.mandatory = [ "right_shift" ];
          };
          to = [ { key_code = "5"; } ];
        }
        {
          description = "Spacebar + H = 6";
          from = {
            key_code = "h";
            modifiers.mandatory = [ "right_shift" ];
          };
          to = [ { key_code = "6"; } ];
        }
        {
          description = "Spacebar + J = 7";
          from = {
            key_code = "j";
            modifiers.mandatory = [ "right_shift" ];
          };
          to = [ { key_code = "7"; } ];
        }
        {
          description = "Spacebar + K = 8";
          from = {
            key_code = "k";
            modifiers.mandatory = [ "right_shift" ];
          };
          to = [ { key_code = "8"; } ];
        }
        {
          description = "Spacebar + L = 9";
          from = {
            key_code = "l";
            modifiers.mandatory = [ "right_shift" ];
          };
          to = [ { key_code = "9"; } ];
        }
        {
          description = "Spacebar + semicolon = 0";
          from = {
            key_code = "semicolon";
            modifiers.mandatory = [ "right_shift" ];
          };
          to = [ { key_code = "0"; } ];
        }
        {
          description = "Spacebar as capslock";
          from = {
            key_code = "spacebar";
            modifiers.optional = [ "any" ];
          };
          to = [ { key_code = "right_shift"; } ];
          to_if_alone = [ { key_code = "spacebar"; } ];
        }
      ];
    }
  ];

  mkSimpleModification = from: to: {
    from.key_code = from;
    to = [ { key_code = to; } ];
  };

  mkFnKey = from: to: {
    from.key_code = from;
    to = [ { key_code = to; } ];
  };

  map = builtins.map;

  # Generate karabiner config JSON
  karabinerConfigJson = builtins.toJSON {
    global = {
      show_in_menu_bar = false;
    };
    profiles = [
      {
        name = "Default profile";
        selected = true;
        complex_modifications = {
          parameters = {
            "basic.to_if_alone_timeout_milliseconds" = 700;
          };
          inherit rules;
        };
        devices = [
          {
            identifiers = {
              is_keyboard = true;
              product_id = 24866;
              vendor_id = 7504;
            };
            ignore = true;
            manipulate_caps_lock_led = false;
          }
          {
            identifiers = {
              is_keyboard = true;
              product_id = 3866;
              vendor_id = 5426;
            };
            manipulate_caps_lock_led = false;
          }
          {
            identifiers = {
              is_keyboard = true;
              product_id = 611;
              vendor_id = 1452;
            };
            simple_modifications = [
              (mkSimpleModification "caps_lock" "delete_or_backspace")
              (mkSimpleModification "right_command" "right_option")
              (mkSimpleModification "right_option" "right_command")
            ];
          }
        ];
        fn_function_keys = [
          (mkFnKey "f1" "display_brightness_decrement")
          (mkFnKey "f2" "display_brightness_increment")
          (mkFnKey "f3" "mission_control")
          (mkFnKey "f4" "launchpad")
          (mkFnKey "f5" "illumination_decrement")
          (mkFnKey "f6" "illumination_increment")
          (mkFnKey "f7" "rewind")
          (mkFnKey "f8" "play_or_pause")
          (mkFnKey "f9" "fastforward")
          (mkFnKey "f10" "mute")
          (mkFnKey "f11" "volume_decrement")
          (mkFnKey "f12" "volume_increment")
        ];
        simple_modifications = [
          (mkSimpleModification "caps_lock" "delete_or_backspace")
          (mkSimpleModification "right_command" "right_option")
          (mkSimpleModification "right_option" "right_command")
        ];
        virtual_hid_keyboard = {
          caps_lock_delay_milliseconds = 0;
          country_code = 0;
          keyboard_type = "ansi";
          keyboard_type_v2 = "iso";
        };
      }
    ];
  };
in
{
  homebrew.casks = [ "karabiner-elements" ];

  system.activationScripts.postActivation.text = ''
        echo "Deploying Karabiner config..."
        mkdir -p /Users/${username}/.config/karabiner
        cat > /Users/${username}/.config/karabiner/karabiner.json << 'KARABINER_EOF'
    ${karabinerConfigJson}
    KARABINER_EOF
        chmod 600 /Users/${username}/.config/karabiner/karabiner.json
        chown ${username}:staff /Users/${username}/.config/karabiner/karabiner.json
  '';
}
