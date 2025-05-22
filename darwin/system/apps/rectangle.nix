{...}:
rec {
  homebrew.casks = [ "rectangle" ];

  system.defaults.CustomUserPreferences."com.knollsoft.Rectangle" = {
    SUEnableAutomaticChecks = 0;
    SUHasLaunchedBefore = 1;
    allowAnyShortcut = 1;
    alternateDefaultShortcuts = 1;
    bottomHalf =     {
        keyCode = 36;
        modifierFlags = 1310720;
    };
    bottomLeft =     {
        keyCode = 115;
        modifierFlags = 1310720;
    };
    bottomRight =     {
        keyCode = 119;
        modifierFlags = 1310720;
    };
    internalTilingNotified = 1;
    launchOnLogin = 1;
    leftHalf =     {
        keyCode = 123;
        modifierFlags = 1310720;
    };
    maximize =     {
        keyCode = 125;
        modifierFlags = 1310720;
    };
    reflowTodo =     {
        keyCode = 45;
        modifierFlags = 786432;
    };
    rightHalf =     {
        keyCode = 124;
        modifierFlags = 1310720;
    };
    subsequentExecutionMode = 0;
    toggleTodo =     {
        keyCode = 11;
        modifierFlags = 786432;
    };
    topHalf =     {
        keyCode = 126;
        modifierFlags = 1310720;
    };
    topLeft =     {
        keyCode = 116;
        modifierFlags = 1310720;
    };
    topRight =     {
        keyCode = 121;
        modifierFlags = 1310720;
    };
  };
}
