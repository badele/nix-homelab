# Don't forget to add :
# - hostname entry on nix/nixos/features/commons/networking.nix
# - firewall rule hosts/hype16/default.nix
{ lib, config, pkgs, ... }:
let

  webport = "3000";
  hostAddress =
    (builtins.elemAt config.networking.interfaces."vlan-adm".ipv4.addresses
      0).address;
  defaultGateway = config.networking.defaultGateway;

  # Function
  # Get Hosts IP
  hostsIps = lib.mapAttrsToList
    (name: host: {
      domain = name;
      answer = host.ipv4;
    })
    config.homelab.hosts;

  # Function
  # Get Alias IP
  aliasIps = lib.flatten (lib.mapAttrsToList
    (name: host:
      let alias = lib.optionals (host.dnsalias != null) host.dnsalias;
      in map
        (entry: {
          domain = entry;
          answer = host.ipv4;
        })
        alias)
    config.homelab.hosts);
in
{

  # networking.vswitches = { br-adm = { interfaces = { vb-adguard = { }; }; }; };

  containers.adguard = {

    autoStart = true;
    privateNetwork = true;
    hostAddress = hostAddress;
    localAddress = "192.168.241.1";

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

      services.resolved.enable = false;
      services.adguardhome = {
        enable = true;
        mutableSettings = false;
        settings = {
          http.address = "0.0.0.0:${webport}";
          schema_version = 29;
          dns = {
            ratelimit = 0;
            bind_hosts = [ "0.0.0.0" ];
            bootstrap_dns = [ "9.9.9.10" "149.112.112.10" ];
            upstream_dns = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4" ];
            rewrites = hostsIps ++ aliasIps;
          };
        };
      };
    };
  };
}
