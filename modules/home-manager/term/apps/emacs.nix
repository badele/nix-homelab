{ lib, pkgs, ... }:
{

  # Install the emacs configuration from below URL
  # https://github.com/badele/idem#quick-install repository
  programs.emacs.enable = true;

  services.emacs = {
    enable = true;
    client.enable = true;
    defaultEditor = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "copilot-language-server"
      ];
  };

  # All neovim plugins list from the https://github.com/badele/idem project
  home.packages = with pkgs; [
    copilot-language-server
    fd
    ripgrep

    symbola # fallback for nerd-fonts, which is required by doom-emacs

    ############################################################################
    # Language support packages are now in separate files
    # See modules/home-manager/term/development/language/
    ############################################################################
  ];
}
