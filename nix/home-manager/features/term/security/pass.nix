{ pkgs, config, lib, ... }: {

  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "$HOME/ghq/github.com/badele/pass";
    };
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
  };
}
