# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # My wallpapers
  wallpapers = final: prev: {
    wallpapers = final.callPackage ../pkgs/wallpapers { };
  };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });

    # rice.colorPalette = with final.lib.nix-rice;
    rice.colorPalette = with inputs.nix-rice.lib;

      let
        # https://github.com/kovidgoyal/kitty-themes/tree/master/themes
        themename = "gruvbox-dark";
        theme = kitty-themes.getThemeByName themename;

        blackDarkenValue = 15;
        darkNormalValue = 90;
        darkBrightValue = 90;
      in
      rec  {
        dark-normal = {
          black = color.darken darkNormalValue theme.color0;
          red = color.darken darkNormalValue theme.color1;
          green = color.darken darkNormalValue theme.color2;
          yellow = color.darken darkNormalValue theme.color3;
          blue = color.darken darkNormalValue theme.color4;
          magenta = color.darken darkNormalValue theme.color5;
          cyan = color.darken darkNormalValue theme.color6;
          white = color.darken darkNormalValue theme.color7;
        };
        dark-bright = {
          black = color.darken darkBrightValue theme.color0;
          red = color.darken darkBrightValue theme.color1;
          green = color.darken darkBrightValue theme.color2;
          yellow = color.darken darkBrightValue theme.color3;
          blue = color.darken darkBrightValue theme.color4;
          magenta = color.darken darkBrightValue theme.color5;
          cyan = color.darken darkBrightValue theme.color6;
          white = color.darken darkBrightValue theme.color7;
        };
        normal = {
          black = theme.color0;
          red = theme.color1;
          green = theme.color2;
          yellow = theme.color3;
          blue = theme.color4;
          magenta = theme.color5;
          cyan = theme.color6;
          white = theme.color7;
        };
        bright = {
          black = theme.color8;
          red = theme.color9;
          green = theme.color10;
          yellow = theme.color11;
          blue = theme.color12;
          magenta = theme.color13;
          cyan = theme.color14;
          white = theme.color15;
        };
        background = color.darken blackDarkenValue theme.color0;
        foreground = color.darken 10 theme.color15;

        cursor_bg = color.darken 10 theme.color15;
        cursor_border = color.darken 10 theme.color15;
        cursor_fg = color.darken blackDarkenValue theme.color0;

        selection_bg = color.darken 10 theme.color4;
        selection_fg = color.darken blackDarkenValue theme.color0;
      };
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
