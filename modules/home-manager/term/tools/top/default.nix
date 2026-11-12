{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    procps
  ];

  xdg.configFile."procps/toprc".source = ./toprc;
}
