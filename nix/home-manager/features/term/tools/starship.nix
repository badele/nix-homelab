# ███████╗████████╗ █████╗ ██████╗ ███████╗██╗  ██╗██╗██████╗ 
# ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██║  ██║██║██╔══██╗
# ███████╗   ██║   ███████║██████╔╝███████╗███████║██║██████╔╝
# ╚════██║   ██║   ██╔══██║██╔══██╗╚════██║██╔══██║██║██╔═══╝ 
# ███████║   ██║   ██║  ██║██║  ██║███████║██║  ██║██║██║     
# ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝     

# Search font symbol => https://www.nerdfonts.com/cheat-sheet
# Configuration => https://starship.rs/config/
{ config, pkgs, inputs, ... }:
let
  hexPalette = with inputs.nix-rice.lib; palette.toRGBHex pkgs.rice.colorPalette;
in
{
  programs.starship = {
    enable = true;

    settings = {
      add_newline = true;
      # pastel sort-by hue | pastel format
      format = ''$status$username$hostname[](bg:${hexPalette.normal.blue} fg:${hexPalette.normal.magenta})$directory[](bg:${hexPalette.bright.blue} fg:${hexPalette.normal.blue})$git_branch$git_status[](bg:${hexPalette.normal.cyan} fg:${hexPalette.bright.blue})$cmd_duration[ ](bg:${hexPalette.background} fg:${hexPalette.normal.cyan})'';
      right_format = "[](bg:${hexPalette.background} fg:${hexPalette.normal.blue})$c$golang[](bg:${hexPalette.normal.blue} fg:${hexPalette.normal.magenta})$time";
      fill = {
        symbol = " ";
        disabled = false;
      };

      status =
        {
          style = "bg:${hexPalette.normal.white} fg:${hexPalette.bright.green}";
          format = "[$symbol$common_meaning \($status\)$signal_name$maybe_int]($style)[](bg:${hexPalette.bright.cyan} fg:${hexPalette.normal.white})";
          map_symbol = true;
          disabled = false;
        };

      username = {
        style_user = "bg:${hexPalette.normal.magenta}";
        style_root = "bg:${hexPalette.normal.red}";
        format = "[$user]($style)";
        show_always = true;
      };

      hostname = {
        format = "[@$hostname]($style)";
        ssh_only = false;
        style = "bg:${hexPalette.normal.magenta}";
      };

      directory = {
        style = "bg:${hexPalette.normal.blue}";
        format = "[ $path ]($style)";
        # truncation_length = 3;
        # truncation_symbol = "…/";

        substitutions = {
          "Documents" = "󰈙";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
        };

      };

      git_branch = {
        symbol = "";
        style = "bg:${hexPalette.bright.blue}";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "bg:${hexPalette.bright.blue}";
        format = "[$all_status$ahead_behind ]($style)";
      };

      golang = {
        symbol = "Go ";
        style = "bg:${hexPalette.normal.blue}";
        format = "[ $symbol ($version) ]($style)";
      };

      # docker_context = {
      #   symbol = " ";
      #   style = "bg:${hexPalette.bright.yellow}";
      #   format = "[ $symbol $context ]($style) $path";
      # };

      # vagrant = {
      #   symbol = " ";
      #   style = "bg:${hexPalette.bright.yellow} fg:${hexPalette.normal.black}";
      #   format = "[ $symbol  $version ]($style)";
      # };

      cmd_duration = {
        disabled = false;
        style = "bg:${hexPalette.normal.cyan} fg:${hexPalette.background}";
        format = "[ 󰅒 $duration ]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R"; # Hour:Minute Format
        style = "bg:${hexPalette.normal.magenta}";
        format = "[ 󰥔 $time ]($style)";
      };

    };
  };
}

