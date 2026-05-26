{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
  ];

  systemd.user.startServices = "sd-switch";

  nix = {
    # Add all flake inputs to registry / CMD: nix registry list
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    #Add all flake inputs to legacy / CMD: echo $NIX_PATH | tr ":" "\n"
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    package = lib.mkForce pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };
}
