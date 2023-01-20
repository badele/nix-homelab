{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dashy;
  configFile = pkgs.runCommand "conf.yml"
    {
      buildInputs = [ pkgs.yj ];
      preferLocalBuild = true;
    } ''
    yj -jy < ${pkgs.writeText "config.json" (builtins.toJSON cfg.settings)} > $out
  '';
in
{
  options.services.dashy = {
    enable = mkEnableOption "dashy";
    imageTag = mkOption {
      type = types.str;
    };
    port = mkOption {
      type = types.int;
    };
    settings = mkOption {
      type = types.attrs;
    };
    extraOptions = mkOption { };
  };

  # docker-dashy.service
  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      dashy = {
        image = "lissy93/dashy:${cfg.imageTag}";
        inherit (cfg) extraOptions;
        environment = {
          TZ = "${config.time.timeZone}";
          PORT = builtins.toString cfg.port;
        };
        volumes = [
          "${configFile}:/app/public/conf.yml"
          # "/tmp/conf.yml:/app/public/conf.yml"
        ];
      };
    };
  };
}
