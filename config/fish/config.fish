##
# onnimonni preferred aliases and functions
##

# Don't use Finnish even if my location is in Finland
set -x LANG "en_US.UTF-8"
set -x LC_ALL "en_US.UTF-8"

##
# Get current conf file directory
# This needs to resolve symlinks from rcm
##
function fish_config_dir
    switch (uname)
    case Darwin # OS-X
        echo ( dirname ( readlink    (status --current-filename) ) )
    case '*'
        echo ( dirname ( readlink -f (status --current-filename) ) )
    end
end

# Use files from this folder and from homebrew /usr/local/sbin
fish_add_path /opt/homebrew/opt/curl/bin
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin
fish_add_path ~/.dotfiles/bin
fish_add_path /usr/local/sbin
# PNPM packages
set -gx PNPM_HOME ~/Library/pnpm
fish_add_path PNPM_HOME

# Rust builded binaries
fish_add_path ~/.cargo/bin

# PNPM
fish_add_path ~/Library/pnpm

# Postgres client
if test -d /opt/homebrew/opt/libpq/bin
    fish_add_path /opt/homebrew/opt/libpq/bin
end

# Setup homebrew for linux
if test -d ~/.linuxbrew/bin
  eval (~/.linuxbrew/bin/brew shellenv)

  # Use homebrew openssl for rbenv
  set -Ux RUBY_CONFIGURE_OPTS --with-openssl-dir=(brew --prefix openssl)
end

set FDIR (fish_config_dir)

source $FDIR/aliases.fish
source $FDIR/prompt.fish
source $FDIR/colors.fish
source $FDIR/yubikey.fish
source $FDIR/local.fish

# Some extra ENV to skip tracking from CLI tools
source $FDIR/no-tracking.fish

# Don't store secrets in git use additional file for them
if test -f ~/.secrets.fish
  source ~/.secrets.fish
end

# Remove temporary variable afterwise
unset FDIR

# Use mise (asdf clone) installed with homebrew
if type -q brew
  if type -q mise
    # Sometimes I forget the name of mise
    alias asdf "mise"
  end
end

# Add custom completions
if test -d ~/.config/fish/completions/
  source ~/.config/fish/completions/*.fish
end

# Add fish completions from homebrew
if test -d /opt/homebrew/share/fish/vendor_completions.d
    source /opt/homebrew/share/fish/vendor_completions.d/*.fish
end
if test -d /opt/homebrew/share/fish/vendor_functions.d
    source /opt/homebrew/share/fish/vendor_functions.d/*.fish
end
