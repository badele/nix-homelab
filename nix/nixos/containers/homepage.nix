# Don't forget to add :
# - hostname entry on nix/nixos/features/commons/networking.nix
# - firewall rule hosts/hype16/default.nix
{ lib, config, pkgs, ... }:
let
  hostAddress =
    (builtins.elemAt config.networking.interfaces."vlan-adm".ipv4.addresses
      0).address;
  defaultGateway = config.networking.defaultGateway;
in
{

  # networking.vswitches = { br-adm = { interfaces = { vb-homepage = { }; }; }; };

  containers.homepage = {

    autoStart = true;
    privateNetwork = true;
    hostAddress = hostAddress;
    localAddress = "192.168.241.2";

    extraFlags = [
      "--drop-capability=CAP_AUDIT_WRITE"
      "--drop-capability=CAP_AUDIT_CONTROL"
      "--drop-capability=CAP_DAC_READ_SEARCH"
      # "--drop-capability=CAP_NET_ADMIN"
      "--drop-capability=CAP_IPC_LOCK"
      "--drop-capability=CAP_IPC_OWNER"
      "--drop-capability=CAP_LEASE"
      "--drop-capability=CAP_LINUX_IMMUTABLE"
      "--drop-capability=CAP_MAC_OVERRIDE"
      "--drop-capability=CAP_NET_BROADCAST"
      "--drop-capability=CAP_SYS_NICE"
      # "--drop-capability=CAP_SYS_ADMIN"
      "--drop-capability=CAP_SYS_BOOT"
      "--drop-capability=CAP_SYS_MODULE"
      "--drop-capability=CAP_SYS_RAWIO"
      "--drop-capability=CAP_SYS_PTRACE"
      "--drop-capability=CAP_SYS_PACCT"
      "--drop-capability=CAP_SYS_NICE"
      "--drop-capability=CAP_SYS_RESOURCE"
      "--drop-capability=CAP_SYS_TIME"
      "--drop-capability=CAP_SYS_TTY_CONFIG"
      "--link-journal=host"
      # "--private-users=pick"
      # "--private-users-chown"
      "--no-new-privileges=yes"
    ];

    config = {

      boot = { specialFileSystems = { }; };

      networking = {
        useDHCP = false;
        defaultGateway = defaultGateway;
        firewall.enable = false;
      };

      systemd = {
        coredump.enable = false;
        oomd.enable = false;
        package = pkgs.systemdMinimal;
        suppressedSystemUnits = [
          "systemd-logind.service"
          "systemd-user-sessions.service"
          "dbus-org.freedesktop.login1.service"
          "systemd-hibernate-clear.service"
          "systemd-bootctl@.service"
          "systemd-bootctl.socket"
          "network-setup.service"
        ];
      };

      services.homepage-dashboard = {
        enable = true;

        widgets = [
          {
            resources = {
              cpu = true;
              disk = "/";
              memory = true;
            };
          }
          {
            search = {
              provider = "duckduckgo";
              target = "_blank";
            };
          }
          {
            traefik = {
              type = "traefik";
              url = "http://192.168.240.16:8080";
            };
          }
        ];

        services = [
          {
            "My First Group" = [{
              "My First Service" = {
                description = "Homepage is awesome";
                href = "http://localhost/";
              };
            }];
          }
          {
            "My Second Group" = [{
              "My Second Service" = {
                description = "Homepage is the best";
                href = "http://localhost/";
              };
            }];
          }
        ];

        bookmarks = [
          {
            Developer = [{
              Github = [{
                abbr = "GH";
                href = "https://github.com/";
              }];
            }];
          }
          {
            Entertainment = [{
              YouTube = [{
                abbr = "YT";
                href = "https://youtube.com/";
              }];
            }];
          }
        ];

      };

    };
  };
}
