##
# Add aliases
##

# Prevent overwriting or deleting by accident
alias cp "cp -iv"
alias mv "mv -iv"
alias rm "rm -iv"

# ls aliases
alias ll "ls -lah"

# Shortcuts
alias h "history"
alias j "jobs"

switch (uname)
case Darwin # Macos
  # Locate is quite shitty in MacOS: https://discussions.apple.com/thread/252219481
  alias locate "mdfind"
end

# If you forgot that this is not zsh
alias where "which -a"

# Lock screen and leave processes running in the background
alias lock "pmset displaysleepnow"

# OSX has strange conventions, use linux conventions instead
alias sha256sum "shasum --algorithm 256"

alias random_password 'env LC_CTYPE=C tr -dc "a-zA-Z0-9-_\$\?" < /dev/urandom | head -c 30'

# Navigation
function cd..  ; cd .. ; end
function ..    ; cd .. ; end
function ...   ; cd ../.. ; end
function ....  ; cd ../../.. ; end
function ..... ; cd ../../../.. ; end

# Syntactic sugar for noobs
alias print "c"
alias filesize "fs"

##
# Fantastic system which automaticly guesses what you wanted run
# Thanks: https://github.com/skithund
# Example:
# $ ech 'hello world'
# fish: Unknown command 'cleorr'
# $ fuck
# $ echo [enter/↑/↓/ctrl+c]
# hello world
##
if command_exists thefuck
  eval (thefuck --alias | tr '\n' ';')
end

# Pretty print json
alias to_pretty_json "python -m json.tool"

# Minify json
alias to_json "python -c 'import sys, json; print json.dumps(json.load(sys.stdin),sort_keys=True)'"
alias to_min_json "python -c 'import sys, json; print json.dumps(json.load(sys.stdin),sort_keys=True)'"

# Always enable colored `grep` output
# Note: `GREP_OPTIONS="--color=auto"` is deprecated, hence the alias usage.
alias grep 'grep --color=auto'
alias fgrep 'fgrep --color=auto'
alias egrep 'egrep --color=auto'

# Allow reloading fish config after changes
alias reload "source ~/.config/fish/config.fish"

# Get week number
alias week 'date +%V'

# IP addresses
alias ip "dig +short myip.opendns.com @resolver1.opendns.com"
alias localip "ipconfig getifaddr en0"
alias ips "ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Flush Directory Service cache
alias dnsflush "dscacheutil -flushcache; and killall -HUP mDNSResponder"

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
