{ ... }:
{
  # Allow more auth attempts so Secretive keys don't exhaust MaxAuthTries
  environment.etc."ssh/sshd_config.d/99-max-auth-tries.conf" = {
    text = ''
      MaxAuthTries 10
    '';
  };
}
