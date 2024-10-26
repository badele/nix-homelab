##########################################################
# NIXOS
##########################################################
{ pkgs
, config
, lib
, ...
}:
let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  extraGroups = [
    "audio"
    "video"
    "wheel"
  ] ++ ifTheyExist [
    "docker"
    "git"
    "libvirtd"
    "network"
    "networkmanager"
    "plugdev"
  ];

in
{
  sops.secrets = {
    "system/user/demo-hash" = {
      sopsFile = ./demovm/secrets.yml;
      neededForUsers = true;
    };
  };

  users.users = {
    # demo user
    demo = {
      isNormalUser = true;
      home = "/home/demo";
      inherit extraGroups;
      shell = pkgs.zsh;
      uid = 1000;
      passwordFile = config.sops.secrets."system/user/demo-hash".path;
      openssh.authorizedKeys.keys = [
      ];
    };
  };
}
