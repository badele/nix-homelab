{
  pkgs,
  ...
}:
{
  imports = [
    # Modules
    ../home-manager/modules/userconf.nix

    # Security (GPG, SSH)
    ../home-manager/term/security/gpg.nix

    # Homogen style (stylix)
    ../home-manager/term/stylix.nix
  ];

  programs.kitty.enable = true;

  home.packages = with pkgs; [
    bat # cat alternative
    curl # HTTP client
    dconf # Dconf editor
    eva # Calculator
    httpie # Curl alternative
    tmux # Terminal multiplexer
    up # UI interactively pipe
    wget # HTTP client
  ];
}
