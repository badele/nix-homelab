{ pkgs, ... }: {

  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    font-awesome
  ];

  fontProfiles = {
    enable = true;
    fontawesome = {
      family = "Font Awesome 6 Free Solid";
      package = pkgs.font-awesome;
    };
    monospace = {
      family = "FiraCode Nerd Font";
      package = pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; };
    };
    regular = {
      family = "Fira Sans";
      package = pkgs.fira;
    };
  };
}
