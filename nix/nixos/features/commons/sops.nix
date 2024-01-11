{ inputs, lib, config, ... }:
let
  key = builtins.elemAt (builtins.filter (k: k.type == "ed25519") config.services.openssh.hostKeys) 0;
  defaultHostSopsFile = ./../../../.. + "/hosts/${config.networking.hostName}/secrets.yml";
in
{
  imports = [
  ];

  # WARNING if move this file, update the sopsFile path
  # Define default secrets.yaml file from target secrets host
  sops.defaultSopsFile =
    if builtins.pathExists defaultHostSopsFile
    then defaultHostSopsFile
    else null;
}
