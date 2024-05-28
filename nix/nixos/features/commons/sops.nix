{ inputs, lib, config, ... }:
let
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
    # can't define null, we set to unused secret file
    else ./../../../../hosts/demo-secrets.yml;
}
