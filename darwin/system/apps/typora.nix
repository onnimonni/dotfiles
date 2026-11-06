{ username, ... }:
{
  # Easier markdown editing with nice copy paste
  homebrew.casks = [
    "typora"
  ];

  home-manager.users.${username}.fileAssociations.duti."abnerworks.Typora" = [
    "net.daringfireball.markdown"
    ".md"
    ".markdown"
  ];
}
