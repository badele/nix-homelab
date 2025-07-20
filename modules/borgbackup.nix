{ pkgs, ... }:
let
  username = "u444061";
  host = "${username}.your-storagebox.de";
  port = "23";

  # Run this from the hetzner network
  # ssh-keyscan -p 23 <host>
  # and update `storagebox-xxx-knowHost` variables
  storagebox-ed25519-knownHosts = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
  storagebox-ecdsa-knownHosts = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==";
  storagebox-rsa-knownHosts = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
in
{
  clan.core.vars.generators.borgbackup = {
    files."borgbackup-ssh-account" = {
      share = true;
    };

    files."borgbackup-ssh-account.pub" = {
      secret = false;
      share = true;
    };

    files."borgbackup-passphrase" = {
      share = true;
    };

    runtimeInputs = [
      pkgs.pwgen
      pkgs.openssh
    ];

    script = ''
      pwgen -s 64 1 > "$out/borgbackup-passphrase"
      ssh-keygen -q -N "" -t ed25519 -f "$out/borgbackup-ssh-account"
    '';
  };

  # ssh-keyscan -p 23 u444061.your-storagebox.de
  programs.ssh.knownHosts = {
    storagebox-rsa.hostNames = [ "[${host}]:${toString port}" ];
    storagebox-rsa.publicKey = storagebox-rsa-knownHosts;

    storagebox-ecdsa.hostNames = [ "[${host}]:${toString port}" ];
    storagebox-ecdsa.publicKey = storagebox-ecdsa-knownHosts;

    storagebox-ed25519.hostNames = [ "[${host}]:${toString port}" ];
    storagebox-ed25519.publicKey = storagebox-ed25519-knownHosts;
  };

}
