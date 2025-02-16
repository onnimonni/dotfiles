# I use zsh when I want to use x86-64 binaries

# Load homebrew autocompletions
[[ $(arch) = "arm64" ]] &&
    eval "$(/opt/homebrew/bin/brew shellenv)" ||
    eval "$(/usr/local/Homebrew/bin/brew shellenv)"