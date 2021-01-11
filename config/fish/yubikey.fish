switch (uname)
case Darwin # OS-X
    echo "YUBIKEY SETUP IS NOT WORKING IN MACOS"
case Linux
	# Launches the gpg agent and setups the needed variables
    set -Ux GPG_TTY (tty)
    unset SSH_AUTH_SOCK # Remove other configs
	set -Ux SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
	gpgconf --launch gpg-agent
end