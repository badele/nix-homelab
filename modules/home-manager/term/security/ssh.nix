{ ... }:
{
  programs.ssh.enable = true;
  programs.ssh.enableDefaultConfig = false;
  programs.ssh.includes = [ "/home/badele/.ssh/devpod" ];
}
