{
  config,
  clan-core,
  ...
}:
{
  imports = [
    clan-core.clanModules.sshd
  ];

  users.users.badele = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
    ];
    uid = 1000;
    openssh.authorizedKeys.keys = config.users.users.root.openssh.authorizedKeys.keys;
  };

  nix = {
    gc.automatic = true;
    gc.dates = "daily";
    gc.options = "--delete-older-than 30d";
  };
}
