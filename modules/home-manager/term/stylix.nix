{
  pkgs,
  ...
}:
{
  # You can preview the palette at ~/.config/stylix/palette.html
  stylix.enable = true;
  stylix.autoEnable = true;

  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/0w/wallhaven-0w3pdr.jpg";
    sha256 = "sha256-xrLfcRkr6TjTW464GYf9XNFHRe5HlLtjpB0LQAh/l6M=";
  };

  # Disable neovim, it managed by https://github.com/badele/vide
  stylix.targets.neovim.enable = false;

  stylix.fonts = {
    serif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Serif";
    };

    sansSerif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans";
    };

    monospace = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans Mono";
    };

    emoji = {
      package = pkgs.noto-fonts-emoji;
      name = "Noto Color Emoji";
    };
  };
}
