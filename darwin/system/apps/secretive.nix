_: {
  # TODO: remove once the keyfob 'default' SSH key is on GitHub and on every
  # server that only trusts the Secretive keys. keyfob is the SSH agent now
  # (programs/keyfob.nix); with homebrew cleanup = "uninstall", dropping this
  # line uninstalls Secretive on the next rebuild.
  homebrew.casks = [ "secretive" ];
}
