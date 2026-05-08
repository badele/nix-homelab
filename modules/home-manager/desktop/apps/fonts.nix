{ pkgs, ... }:
{
  imports = [
    ../../modules/font.nix
  ];

  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    font-awesome
  ];

  fontProfiles.enable = true;
  fontProfiles.fontawesome.family = "Font Awesome 6 Free Solid";
  fontProfiles.fontawesome.package = pkgs.font-awesome;
  fontProfiles.monospace.family = "FiraCode Nerd Font";
  fontProfiles.monospace.package = pkgs.nerd-fonts.fira-code;
  fontProfiles.regular.family = "Fira Sans";
  fontProfiles.regular.package = pkgs.fira;
}
