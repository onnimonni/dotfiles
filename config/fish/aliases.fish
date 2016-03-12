##
# Update dotfiles from origin
##
function update-dotfiles --description 'Update changes to ~/.dotfiles'
  git -C ~/.dotfiles pull origin master
  # Update new symlinks but ssh
  rcup -d ~/.dotfiles -x LICENSE -x README.md -x ssh
end

##
# Add aliases
##

# Prevent overwriting or deleting by accident
alias cp "cp -iv"
alias mv "mv -iv"
alias rm "rm -iv"

# Shortcuts
alias g "git"
alias h "history"
alias j "jobs"

# Navigation
function cd..  ; cd .. ; end
function ..    ; cd .. ; end
function ...   ; cd ../.. ; end
function ....  ; cd ../../.. ; end
function ..... ; cd ../../../.. ; end

# `cat` with beautiful colors. requires Pygments installed.
#                  sudo easy_install -U Pygments
function c --description 'Print file contents with colors'
  if command_exists pygmentize
    pygmentize -O style=monokai -f console256 -g $argv
  else
    cat --color=auto $argv
  end
end
alias print "c" # Syntactic sugar for noobs

# File size
function fs --description 'Print file size recursively'
  du -hs $argv | cut -f -1 | tr -d ' '
end
alias filesize "fs" # Syntactic sugar for noobs

##
# Skip all custom checks in my custom scripts
##
function run-it-please
  begin
    set -lx SKIP_CUSTOM_CHECKS true
    eval command $history[1]
  end
end

# Always enable colored `grep` output
# Note: `GREP_OPTIONS="--color=auto"` is deprecated, hence the alias usage.
alias grep 'grep --color=auto'
alias fgrep 'fgrep --color=auto'
alias egrep 'egrep --color=auto'

# Enable aliases to be sudo’ed (these are basically the only which ever occur)
function sudo
  if test "$argv" = !!
    eval command sudo $history[1]
  else if test "$argv" = "ll"
    command sudo ls -lah $colorflag
  else
    command sudo $argv
  end
end

# Allow reloading fish config after changes
alias reload "source ~/.config/fish/config.fish"

# Get week number
alias week 'date +%V'

# IP addresses
alias ip "dig +short myip.opendns.com @resolver1.opendns.com"
alias localip "ipconfig getifaddr en0"
alias ips "ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Flush Directory Service cache
alias flush "dscacheutil -flushcache; and killall -HUP mDNSResponder"

# View HTTP traffic
alias sniff "sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump "sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# .DS_Store is so evil
alias scp "rsync -avz --exclude '.DS_Store'"
alias rsync "rsync --exclude '.DS_Store'"

# Canonical hex dump; some systems have this symlinked
command -v hd > /dev/null; or alias hd "hexdump -C"

# OS X has no `md5sum`, so use `md5` as a fallback
command -v md5sum > /dev/null; or alias md5sum "md5"

# OS X has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum > /dev/null; or alias sha1sum "shasum"

# Recursively delete `.DS_Store` files
alias cleanup "find . -type f -name '*.DS_Store' -ls -delete"

# Run docker commands in project with docker-compose.yml
function dexec
    docker exec -it (docker-compose ps -q web) $argv
end

##
# Check headers from curl with normal GET method
# Usage: $ headers google.fi
##
alias headers "curl -sD - -o /dev/null"
