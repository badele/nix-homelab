{
  config,
  lib,
  ...
}:
let
  colors = config.lib.stylix.colors;

  hexPairToDec = pair: toString (lib.fromHexString pair);

  hexToRgb =
    hex:
    let
      h = lib.removePrefix "#" hex;
    in
    "${hexPairToDec (builtins.substring 0 2 h)},${hexPairToDec (builtins.substring 2 2 h)},${
      hexPairToDec (builtins.substring 4 2 h)
    }";
in
{
  # on KDE session, For applying theme, run this command `plasma-apply-colorscheme STYLIX-THEME-NAME`
  # ex: Replace STYLIX-THEME-NAME with StylixTokyoNightMoon
  # Kvanum crashes with plasma 6, so I disable it for now, but I want to enable it in the future

  stylix.targets.qt.enable = false;
  qt = {
    enable = true;
    platformTheme.name = lib.mkDefault "kde";
    style.name = "Breeze";
  };

  xdg.dataFile."color-schemes/StylixTokyoNightMoon.colors".text = ''
    [General]
    Name=StylixTokyoNightMoon
    ColorScheme=StylixTokyoNightMoon
    shadeSortColumn=true

    [Colors:Window]
    BackgroundNormal=${hexToRgb colors.base00}
    BackgroundAlternate=${hexToRgb colors.base01}
    ForegroundNormal=${hexToRgb colors.base05}
    ForegroundInactive=${hexToRgb colors.base03}
    DecorationFocus=${hexToRgb colors.base0D}
    DecorationHover=${hexToRgb colors.base0C}

    [Colors:View]
    BackgroundNormal=${hexToRgb colors.base00}
    BackgroundAlternate=${hexToRgb colors.base01}
    ForegroundNormal=${hexToRgb colors.base05}
    ForegroundInactive=${hexToRgb colors.base03}
    DecorationFocus=${hexToRgb colors.base0D}
    DecorationHover=${hexToRgb colors.base0C}

    [Colors:Button]
    BackgroundNormal=${hexToRgb colors.base01}
    BackgroundAlternate=${hexToRgb colors.base02}
    ForegroundNormal=${hexToRgb colors.base05}
    ForegroundInactive=${hexToRgb colors.base03}
    DecorationFocus=${hexToRgb colors.base0D}
    DecorationHover=${hexToRgb colors.base0C}

    [Colors:Selection]
    BackgroundNormal=${hexToRgb colors.base0D}
    BackgroundAlternate=${hexToRgb colors.base0C}
    ForegroundNormal=${hexToRgb colors.base00}
    ForegroundInactive=${hexToRgb colors.base01}
    DecorationFocus=${hexToRgb colors.base0D}
    DecorationHover=${hexToRgb colors.base0C}

    [Colors:Tooltip]
    BackgroundNormal=${hexToRgb colors.base01}
    BackgroundAlternate=${hexToRgb colors.base02}
    ForegroundNormal=${hexToRgb colors.base05}
    ForegroundInactive=${hexToRgb colors.base03}
    DecorationFocus=${hexToRgb colors.base0D}
    DecorationHover=${hexToRgb colors.base0C}

    [Colors:Complementary]
    BackgroundNormal=${hexToRgb colors.base00}
    BackgroundAlternate=${hexToRgb colors.base01}
    ForegroundNormal=${hexToRgb colors.base05}
    ForegroundInactive=${hexToRgb colors.base03}
    DecorationFocus=${hexToRgb colors.base0D}
    DecorationHover=${hexToRgb colors.base0C}

    [WM]
    activeBackground=${hexToRgb colors.base00}
    activeForeground=${hexToRgb colors.base05}
    inactiveBackground=${hexToRgb colors.base01}
    inactiveForeground=${hexToRgb colors.base03}
  '';
}
