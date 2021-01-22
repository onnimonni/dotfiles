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
set PATH $PATH ~/.dotfiles/bin /usr/local/sbin

# Add yarn modules
if test -d ~/.config/yarn/global/node_modules/.bin
    set PATH ~/.config/yarn/global/node_modules/.bin $PATH
end

# Add yarn scripts
if test -d ~/.yarn/bin
    set PATH $PATH ~/.yarn/bin
end

# Add rbenv controlled ruby
if test -d ~/.rbenv/shims
    set PATH $PATH ~/.rbenv/shims
end

# Add npm libraries to the end of path
if test -d ~/.npm-packages/bin/
    set PATH $PATH ~/.npm-packages/bin/
end

# Add pip executables to path
if test -d ~/.local/bin/
    set PATH $PATH ~/.local/bin/
end

# Add php scripts to the end of path
if test -d ~/.composer/vendor/bin/
    set PATH $PATH ~/.composer/vendor/bin/
end

# Kubernetes plugins through krew
if test -d ~/.krew/bin
  set PATH $PATH ~/.krew/bin
  
  # Use these aliases for backwards compatibility
  alias kubectx "kubectl ctx"
  alias kubens "kubectl ns"
end

# Setup homebrew for linux
if test -d ~/.linuxbrew/bin
  eval (~/.linuxbrew/bin/brew shellenv)

  # Use homebrew openssl for rbenv
  set -Ux RUBY_CONFIGURE_OPTS --with-openssl-dir=(brew --prefix openssl)
end

set FDIR (fish_config_dir)

source $FDIR/aliases.fish
source $FDIR/hacks.fish
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
