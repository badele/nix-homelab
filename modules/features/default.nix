{ lib, inputs }:
let
  # Auto-discover all feature modules in this directory
  # Each subdirectory with a default.nix is considered a feature module
  featuresDir = ./.;

  # Get all directories in modules/features/
  allEntries = builtins.readDir featuresDir;

  # Filter to only directories
  directories = lib.filterAttrs (name: type: type == "directory") allEntries;

  # Check if each directory has a default.nix and import it
  featureModules = lib.mapAttrsToList
    (name: _:
      let modulePath = featuresDir + "/${name}/default.nix";
      in if builtins.pathExists modulePath then modulePath else null
    )
    directories;

  # Remove null entries (directories without default.nix)
  validModules = lib.filter (x: x != null) featureModules;
in
{
  # Make inputs available to all imported modules
  _module.args = { inherit inputs; };

  # Return list of all feature modules to import
  imports = validModules;
}
