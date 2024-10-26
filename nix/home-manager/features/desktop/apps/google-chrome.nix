{ pkgs, config, lib, inputs, ... }:
{
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
      "mhccpoafgdgbhnjfhkcmgknndkeenfhe" # InVID & WeVerify (Image fake detector)
    ];
  };
}
