{ ... }:
{
  programs.ssh = {
    enable = true;
    includes = [ "/home/badele/.ssh/devpod" ];
  };
}
