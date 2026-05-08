{ pkgs, ... }:
{

  # Install the emacs configuration from this https://github.com/badele/idem#installation repository
  programs.emacs.enable = true;

  services.emacs = {
    enable = true;
    client.enable = true;
    defaultEditor = true;
  };

  # All neovim plugins list from the https://github.com/badele/idem project
  home.packages = with pkgs; [
    # Language support packages are now in separate files:
    # - nix/home-manager/features/language/ansible.nix
    # - nix/home-manager/features/language/bash.nix
    # - nix/home-manager/features/language/c.nix
    # - nix/home-manager/features/language/d2.nix
    # - nix/home-manager/features/language/go.nix
    # - nix/home-manager/features/language/javascript.nix
    # - nix/home-manager/features/language/latex.nix
    # - nix/home-manager/features/language/ledger.nix
    # - nix/home-manager/features/language/lua.nix
    # - nix/home-manager/features/language/markdown.nix
    # - nix/home-manager/features/language/nix.nix
    # - nix/home-manager/features/language/openscad.nix
    # - nix/home-manager/features/language/python.nix
    # - nix/home-manager/features/language/rust.nix
    # - nix/home-manager/features/language/scala.nix
    # - nix/home-manager/features/language/terraform.nix
    # - nix/home-manager/features/language/yaml.nix
  ];
}
