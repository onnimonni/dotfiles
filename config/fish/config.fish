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

# Add npm libraries to the end of path
if test -d ~/.npm-packages/bin/
    set PATH $PATH ~/.npm-packages/bin/
end

# Add php scripts to the end of path
if test -d ~/.composer/vendor/bin/
    set PATH $PATH ~/.composer/vendor/bin/
end

set FDIR (fish_config_dir)

source $FDIR/aliases.fish
source $FDIR/hacks.fish
source $FDIR/prompt.fish
source $FDIR/colors.fish

# Use remote hacks if connection is not local and local hacks otherwise
if test -d $SSH_CONNECTION
  source $FDIR/local.fish
  # Don't store secrets in git
  source ~/.secrets.fish
else
  source $FDIR/remote.fish
end

# Remove temporary variable afterwise
unset FDIR
