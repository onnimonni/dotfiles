switch (uname)
case Darwin
	# Use Secretive as ssh agent instead
	set -x SSH_AUTH_SOCK /Users/onnimonni/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
case Linux
	# Launches the gpg agent and setups the needed variables
    set -Ux GPG_TTY (tty)
    unset SSH_AUTH_SOCK # Remove other configs
	set -Ux SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
	gpgconf --launch gpg-agent
end