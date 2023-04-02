{ pkgs, config, lib, ... }: {

  programs.browserpass.enable = true;
  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "$HOME/ghq/github.com/badele/pass";
    };
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
  };

  # home.persistence = {
  #   "/persist/user/${config.home.username}".directories = [ ".password-store" ];
  # };
}
