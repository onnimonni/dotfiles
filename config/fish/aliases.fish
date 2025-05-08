##
# Add aliases
##

# Prevent overwriting or deleting by accident
alias cp "cp -iv"
alias mv "mv -iv"
alias rm "rm -iv"

# Shortcuts
alias h "history"
alias j "jobs"

switch (uname)
case Darwin # Macos
  # Locate is quite shitty in MacOS: https://discussions.apple.com/thread/252219481
  alias locate "mdfind"

  # Force public Wifi login if it didn't open automatically
  function login-public-wifi
    killall -HUP mDNSResponder
    open -a Safari http://captive.apple.com/hotspot-detect.html
  end
end

alias backup-vscode "cp /Users/onnimonni/Library/Application\ Support/Code/User/*.json .vscode-config/"

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
alias to_pretty_json "jq -r"

# Minify json
alias to_json "jq -r"
alias to_min_json "jq -r -c"

# Use eza instead of ls
if command_exists eza
  # Use eza instead of ls
  alias ls "eza"
  # This allows still overriding --sort since later args take precedence
  # This is what I use most of the time
  alias ll "eza --long --all --sort date"

  alias lsd "eza --long --dirs-only"
else
  # Use ls instead of eza
  alias ll "ls -lah"
  alias lsd "ls -ld */"
end

# See into zip file
function lszip
  if not isatty stdin
    # Read the piped data
    while read -l line
      echo $line | xargs -n1 atool -l
    end
  else
    echo $argv | xargs -n1 atool -l
  end
end
function zipcat
  if not isatty stdin
    # Read the piped data
    while read -l line
      echo $line | xargs -n1 atool -c
    end
  else
    echo $argv | xargs -n1 atool -c
  end
end
alias extract "atool -x"

# Help figure out what data looks like
function investigate-file --description 'Shows human readable contents of many large files'
  set -l file_path $argv[1]
  set -l file_type_info (file -b $file_path)
  # Branch based on the file type information
  switch (file -b $file_path)
    case '*Zip archive data*' '*gzip compressed data*'
      # TODO: There seems to be more recent version of atool: https://github.com/z3ntu/atool
      # TODO: Check if this atool can be replaced in homebrew
      # TODO: --quiet option is not working with zip files:
      # $atool -q -l swagger.zip
      # Length      Date    Time    Name
      # ---------  ---------- -----   ----
      # 261775  03-23-2025 12:21   swagger.json
      # ---------                     -------
      # 261775                     1 file
      atool -l $file_path

      # TODO: if you can easily check that the archive contains just one file
      # you can use `atool -c` to extract it and do further analysis
    case '*JSON data*' # Matches if "CSV text" is in the file type string
      # For small files, use jq to pretty print
      if test (du -k $file_path | awk '{print $1}') -lt 20
        echo "$file_path: JSON"
        jq . $file_path
      else
        echo "$file_path: JSON (too large to pretty print)"
        duckdb -c """
          SELECT * EXCLUDE(avg,std,q25,q50,q75) REPLACE(LEFT(min, 60) as min, LEFT(max, 60) as max)
          FROM (
            SUMMARIZE (
              FROM read_json_auto('$file_path', maximum_object_size=3e8, sample_size=100_000)
            )
          );
          FROM read_json_auto('$file_path', maximum_object_size=3e8, sample_size=100_000);
        """
      end
    case '*CSV text*' # Matches if "CSV text" is in the file type string
        echo "$file_path: CSV"
        duckdb -c """
          SELECT * EXCLUDE(avg,std,q25,q50,q75) REPLACE(LEFT(min, 65) as min, LEFT(max, 65) as max)
          FROM (
            SUMMARIZE (
              FROM read_csv_auto('$file_path')
            )
          );
          FROM read_csv_auto('$file_path');
        """
    case '*SQLite*' # Matches if "SQLite" is in the file type string
        echo "This is an SQLite file: $file_type_info"
        duckdb $file_path -c """
          SELECT * EXCLUDE(database_name, database_oid, schema_name, schema_oid, table_oid, internal, temporary, sql)
          FROM duckdb_tables()
          ORDER BY estimated_size DESC;
        
          SET VARIABLE tables_sorted_by_size = (
              SELECT ARRAY_AGG(table_name ORDER BY estimated_size DESC)
              FROM duckdb_tables()
          );

          -- FIXME: This might scan the whole table again
          SELECT getvariable('tables_sorted_by_size')[1] as table_name,* EXCLUDE(q25,q50,q75) REPLACE(LEFT(min, 40) as min, LEFT(max, 40) as max) FROM (
            SUMMARIZE FROM sqlite_scan('$file_path', getvariable('tables_sorted_by_size')[1])
          );
          SELECT getvariable('tables_sorted_by_size')[2] as table_name,* EXCLUDE(q25,q50,q75) REPLACE(LEFT(min, 40) as min, LEFT(max, 40) as max) FROM (
            SUMMARIZE FROM sqlite_scan('$file_path', getvariable('tables_sorted_by_size')[2])
          );
        """
    case '*' # Default case for any other file type
        echo "UNKNOWN file: No special handling for this file type."
        echo $file_type_info
  end
end

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
# Stop overriding the scp alias just in case if some software need it
#alias scp "rsync -avz --exclude '.DS_Store'"
alias rsync "rsync --exclude '.DS_Store'"

# Canonical hex dump; some systems have this symlinked
command -v hd > /dev/null; or alias hd "hexdump -C"

# OS X has no `md5sum`, so use `md5` as a fallback
command -v md5sum > /dev/null; or alias md5sum "md5"

# OS X has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum > /dev/null; or alias sha1sum "shasum"

# Recursively delete `.DS_Store` files
alias cleanup "find . -type f -name '*.DS_Store' -ls -delete"
