{
  config,
  ...
}:
{
  imports = [
    ../../home-manager/term/apps/neovim.nix
    ../../home-manager/term/apps/emacs.nix

    ../../home-manager/term/development/base.nix
    ../../home-manager/term/development/aws.nix
    ../../home-manager/term/development/language/all.nix
  ];

  stylix.targets.neovim.enable = false; # Disable neovim, it managed by https://github.com/badele/vide
  stylix.targets.emacs.enable = false; # Disable emacs, it managed by https://github.com/badele/idem

  programs = {
    git = {
      enable = true;
      signing = {
        key = config.home.userconf.user.gpg.id;
        signByDefault = true;
      };

      settings = {
        user = {
          name = config.home.userconf.user.contact.name;
          email = config.home.userconf.user.contact.email;
        };

        core.pager = "delta";
        interactive.difffilter = "delta --color-only --features=interactive";
        delta.side-by-side = true;
        delta.navigate = true;
        merge.conflictstyle = "diff3";
      };
    };
  };
}
