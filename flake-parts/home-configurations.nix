{ inputs, self, ... }:
{
  flake.homeConfigurations = {
    ########################################################################
    # b4d14
    ########################################################################
    "root@b4d14" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs =
        inputs.nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
      extraSpecialArgs = { inherit inputs; outputs = self; };
      modules = [
        # > Our main home-manager configuration file <
        ../configuration/users/root/b4d14.nix
      ];
    };

    "badele@b4d14" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs =
        inputs.nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
      extraSpecialArgs = { inherit inputs; outputs = self; };
      modules = [
        # > Our main home-manager configuration file <
        inputs.nur.modules.homeManager
        ../configuration/users/badele/b4d14.nix
      ];
    };

    ########################################################################
    # sadhome
    ########################################################################
    "root@sadhome" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs =
        inputs.nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
      extraSpecialArgs = { inherit inputs; outputs = self; };
      modules = [
        # > Our main home-manager configuration file <
        ../nix/home-manager/users/root/sadhome.nix
      ];
    };

    "badele@sadhome" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs =
        inputs.nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
      extraSpecialArgs = { inherit inputs; outputs = self; };
      modules = [
        # > Our main home-manager configuration file <
        ../configuration/users/badele/sadhome.nix
      ];
    };

    "sadele@sadhome" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs =
        inputs.nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
      extraSpecialArgs = { inherit inputs; outputs = self; };
      modules = [
        # > Our main home-manager configuration file <
        ../configuration/users/sadele/sadhome.nix
      ];
    };

    ########################################################################
    # rpi40
    ########################################################################
    "badele@rpi40" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs =
        inputs.nixpkgs.legacyPackages.aarch64-linux; # Home-manager requires 'pkgs' instance
      extraSpecialArgs = { inherit inputs; outputs = self; };
      modules = [
        # > Our main home-manager configuration file <
        ../configuration/users/badele/rpi40.nix
      ];
    };

    ########################################################################
    # srvhoma
    ########################################################################
    "root@srvhoma" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs =
        inputs.nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
      extraSpecialArgs = { inherit inputs; outputs = self; };
      modules = [
        # > Our main home-manager configuration file <
        ../configuration/users/root/srvhoma.nix
      ];
    };

    "badele@srvhoma" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs =
        inputs.nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
      extraSpecialArgs = { inherit inputs; outputs = self; };
      modules = [
        # > Our main home-manager configuration file <
        inputs.nur.modules.homeManager
        ../configuration/users/badele/srvhoma.nix
      ];
    };

    ########################################################################
    # demo
    ########################################################################
    "root@demovm" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs =
        inputs.nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
      extraSpecialArgs = { inherit inputs; outputs = self; };
      modules = [
        # > Our main home-manager configuration file <
        ../configuration/users/root/demo.nix
      ];
    };

    "badele@demovm" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs =
        inputs.nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
      extraSpecialArgs = { inherit inputs; outputs = self; };
      modules = [
        # > Our main home-manager configuration file <
        inputs.nur.modules.homeManager
        ../configuration/users/badele/demo.nix
      ];
    };
  };
}
