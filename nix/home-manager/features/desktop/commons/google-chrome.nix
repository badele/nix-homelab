{ pkgs, config, lib, inputs, ... }:
{
  programs.browserpass = {
    enable = config.programs.chromium.enable;
    browsers = [
      "chromium"
    ];
  };

  programs.chromium = {
    enable = true;
    extensions = [
      "gcaimhkfmliahedmeklebabdgagipbia" # Archive page
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "oncbjlgldmiagjophlhobkogeladjijl" # Bookmark cleaner
      "hmbkmkdhhlgemdgeefnhfaffdpddohpa" # Crypto Tab
      "fihnjjcciajhdojfnbdddfaoknhalnja" # I don't care cookies
      "gccahjgcckaemgpliioopngfgdaceffo" # Spell Merci App 
      "noaijdpnepcgjemiklgfkcfbkokogabh" # Translation
      "fiabciakcmgepblmdkmemdbbkilneeeh" # Tab suspender
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
      "naepdomgkenhinolocfifgehidddafch" # browserpass
    ];
  };

  # home.persistence = {
  #   "/persist/user/${config.home.username}".directories = [ ".config/google-chrome" ];
  # };
}
