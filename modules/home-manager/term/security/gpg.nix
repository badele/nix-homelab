{
  pkgs,
  config,
  lib,
  ...
}:
let
  fetchKey =
    {
      url,
      sha256 ? lib.fakeSha256,
    }:
    builtins.fetchurl { inherit sha256 url; };

in
{
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    sshKeys = [ config.home.userconf.user.gpg.id ];
    pinentry.package = if config.gtk.enable then pkgs.pinentry-qt else pkgs.pinentry-curses;
    enableExtraSocket = true;
  };

  programs = {
    # Start gpg-agent if it's not running or tunneled in
    # SSH does not start it automatically, so this is needed to avoid having to use a gpg command at startup
    # https://www.gnupg.org/faq/whats-new-in-2.1.html#autostart
    zsh.loginExtra = "gpgconf --launch gpg-agent";

    gpg = {
      enable = true;
      settings = {
        trust-model = "tofu+pgp";
      };
      publicKeys = [
        {
          source = fetchKey {
            url = config.home.userconf.user.gpg.url;
            sha256 = config.home.userconf.user.gpg.sha256;
          };
          trust = 5;
        }
      ];
    };
  };

  # Link /run/user/$UID/gnupg to ~/.gnupg-sockets
  # So that SSH config does not have to know the UID
  systemd.user.services.link-gnupg-sockets = {
    Unit = {
      Description = "link gnupg sockets from /run to /home";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/ln -Tfs /run/user/%U/gnupg %h/.gnupg-sockets";
      ExecStop = "${pkgs.coreutils}/bin/rm $HOME/.gnupg-sockets";
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
