{ config, pkgs, inputs, ... }:

let
  hexPalette = with inputs.nix-rice.lib; palette.toRGBHex pkgs.rice.colorPalette;
in
{
  programs.wezterm = {
    enable = true;

    # colorSchemes = {
    #   "usertheme" = {
    #
    #     foreground = hexPalette.foreground;
    #     background = hexPalette.background;
    #
    #     ansi = [
    #       hexPalette.normal.black
    #       hexPalette.normal.red
    #       hexPalette.normal.green
    #       hexPalette.normal.yellow
    #       hexPalette.normal.blue
    #       hexPalette.normal.magenta
    #       hexPalette.normal.cyan
    #       hexPalette.normal.white
    #     ];
    #
    #     brights = [
    #       hexPalette.bright.black
    #       hexPalette.bright.red
    #       hexPalette.bright.green
    #       hexPalette.bright.yellow
    #       hexPalette.bright.blue
    #       hexPalette.bright.magenta
    #       hexPalette.bright.cyan
    #       hexPalette.bright.white
    #     ];
    #
    #     cursor_bg = hexPalette.cursor_bg;
    #     cursor_border = hexPalette.cursor_border;
    #     cursor_fg = hexPalette.cursor_fg;
    #     selection_fg = hexPalette.selection_fg;
    #     selection_bg = hexPalette.selection_bg;
    #   };
    # };
    #font = wezterm.font("${config.fontProfiles.monospace.family}"),
    # extraConfig = /* lua */ ''
    #   return {
    #     font_size = 12.0,
    #     color_scheme = "usertheme",
    #     hide_tab_bar_if_only_one_tab = true,
    #     window_close_confirmation = "NeverPrompt",
    #     set_environment_variables = {
    #       TERM = 'wezterm',
    #     },
    #     -- config.disable_default_key_bindings = true
    #     keys = {
    #       {
    #         key = 'F',
    #         mods = 'SHIFT|CTRL',
    #         action = wezterm.action.DisableDefaultAssignment,
    #       }
    #     },
    #   }
    # '';
  };
}
