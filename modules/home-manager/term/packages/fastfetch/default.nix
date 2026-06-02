{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    fastfetch # neofetch like
  ];

  home.file.".config/fastfetch/config.jsonc".source = ./config.jsonc;

}
