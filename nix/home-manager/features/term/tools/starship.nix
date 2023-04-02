# ███████╗████████╗ █████╗ ██████╗ ███████╗██╗  ██╗██╗██████╗ 
# ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██║  ██║██║██╔══██╗
# ███████╗   ██║   ███████║██████╔╝███████╗███████║██║██████╔╝
# ╚════██║   ██║   ██╔══██║██╔══██╗╚════██║██╔══██║██║██╔═══╝ 
# ███████║   ██║   ██║  ██║██║  ██║███████║██║  ██║██║██║     
# ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝     

# Search font symbol => https://www.nerdfonts.com/cheat-sheet
# Configuration => https://starship.rs/config/
{ config, pkgs, ... }:
let
  inherit (config.colorscheme) colors;
in
{
  programs.starship = {
    enable = true;

    settings = {
      add_newline = true;
      format = ''$status$username$hostname[](bg:#${colors.base0E} fg:#${colors.base0F})$directory[](bg:#${colors.base0D} fg:#${colors.base0E})$git_branch$git_status[](bg:#${colors.base0C} fg:#${colors.base0D})$cmd_duration[ ](bg:#${colors.base00} fg:#${colors.base0C})'';
      right_format = "[](bg:#${colors.base00} fg:#${colors.base0C})$c$golang[](bg:#${colors.base0C} fg:#${colors.base0B})$docker_context[](bg:#${colors.base0B} fg:#${colors.base0A})$time";
      fill = {
        symbol = " ";
        disabled = false;
      };

      status =
        {
          style = "bg:#${colors.base07} fg:#${colors.base03}";
          format = "[$symbol$common_meaning \($status\)$signal_name$maybe_int]($style)[](bg:#${colors.base0F} fg:#${colors.base07})";
          map_symbol = true;
          disabled = false;
        };

      username = {
        style_user = "bg:#${colors.base0F}";
        style_root = "bg:#${colors.base08}";
        format = "[$user]($style)";
        show_always = true;
      };

      hostname = {
        format = "[@$hostname]($style)";
        ssh_only = false;
        style = "bg:#${colors.base0F}";
      };

      directory = {
        style = "bg:#${colors.base0E}";
        format = "[ $path ]($style)";
        # truncation_length = 3;
        # truncation_symbol = "…/";

        substitutions = {
          "Documents" = " ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
        };

      };

      git_branch = {
        symbol = "";
        style = "bg:#${colors.base0D}";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "bg:#${colors.base0D}";
        format = "[$all_status$ahead_behind ]($style)";
      };

      golang = {
        symbol = " ";
        style = "bg:#${colors.base0C}";
        format = "[ $symbol ($version) ]($style)";
      };

      docker_context = {
        symbol = " ";
        style = "bg:#${colors.base0B}";
        format = "[ $symbol $context ]($style) $path";
      };

      # vagrant = {
      #   symbol = " ";
      #   style = "bg:#${colors.base0B} fg:#${colors.base00}";
      #   format = "[ $symbol  $version ]($style)";
      # };

      cmd_duration = {
        disabled = false;
        style = "bg:#${colors.base0C} fg:#${colors.base00}";
        format = "[ 祥 $duration ]($style)";
      };

      time = {
        disabled = false;
        time_format = "%R"; # Hour:Minute Format
        style = "bg:#${colors.base0A} fg:#${colors.base00}";
        format = "[  $time ]($style)";
      };

    };
  };
}
