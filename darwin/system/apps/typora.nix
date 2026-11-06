{ username, ... }:
{
  # Easier markdown editing with nice copy paste
  homebrew.casks = [
    "typora"
  ];

  home-manager.users.${username}.fileAssociations."abnerworks.Typora" = [
    "md"
    "markdown"
  ];
}
