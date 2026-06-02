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

  # After a nixos-rebuild, start the sd-switch service to apply the new configuration
  systemd.user.startServices = "sd-switch";

  nix = {
    # Add all flake inputs to registry / CMD: nix registry list
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    #Add all flake inputs to legacy / CMD: echo $NIX_PATH | tr ":" "\n"
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    # Pin the Nix binary used by Home Manager to the one from nixpkgs.
    # mkForce ensures this value wins over weaker definitions from other modules.
    package = lib.mkForce pkgs.nix;

    # Runtime configuration for Nix commands executed in the user environment.
    settings = {
      # Enable modern Nix CLI and flakes support for user-level commands.
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Avoid warnings when running commands from a git worktree with local changes.
      warn-dirty = false;
    };
  };
}
