##
# onnimonni preferred aliases and functions
##

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
fish_add_path /opt/homebrew/bin
fish_add_path ~/.dotfiles/bin
fish_add_path /usr/local/sbin
# PNPM packages
set -gx PNPM_HOME ~/Library/pnpm
fish_add_path PNPM_HOME

# Rust builded binaries
fish_add_path ~/.cargo/bin

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

# Don't store secrets in git use additional file for them
if test -f ~/.secrets.fish
  source ~/.secrets.fish
end

# Remove temporary variable afterwise
unset FDIR

# TODO: rtx doesn't give nice warnings that certain new thing is not installed like asdf does
# Use rtx (asdf clone) installed with homebrew
#if type -q brew
#  if type -q rtx
#    rtx activate | source
#  end
#end

# Use direnv to automatically load .env
if type -q direnv
  direnv hook fish | source
end

# Add fish completions from homebrew
if test -d /opt/homebrew/share/fish/vendor_completions.d
    source /opt/homebrew/share/fish/vendor_completions.d/*.fish
end
if test -d /opt/homebrew/share/fish/vendor_functions.d
    source /opt/homebrew/share/fish/vendor_functions.d/*.fish
end

# Needs to happen at last
source $FDIR/hacks.fish
