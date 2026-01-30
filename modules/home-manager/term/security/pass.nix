{
  pkgs,
  ...
}:
{
  programs.password-store.enable = true;
  programs.password-store.settings.PASSWORD_STORE_DIR = "$HOME/ghq/github.com/badele/pass";
  programs.password-store.package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);

  programs.browserpass.enable = true;
  programs.browserpass.browsers = [
    "chromium"
    "firefox"
  ];
}
