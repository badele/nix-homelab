{
  config,
  lib,
  inputs,
  mkFeatureOptions,
  ...
}:
with lib;
with types;

let
  appName = "proxmox";
  appDisplayName = "Proxmox VE";
  appCategory = "Core Services";
  appIcon = "proxmox";
  appPlatform = "nixos";
  appDescription = "Virtualization host with Proxmox VE on NixOS";
  appUrl = "https://github.com/SaumonNet/proxmox-nixos";
  appPinnedVersion = inputs.proxmox-nixos.rev or null;

  cfg = config.homelab.features.${appName};
  system = config.nixpkgs.hostPlatform.system;
  exposedURL = "https://${cfg.ipAddress}:8006";

  ipAddressModule = {
    options = {
      address = mkOption {
        type = str;
        description = "IP address.";
      };

      prefixLength = mkOption {
        type = int;
        description = "Subnet prefix length.";
      };
    };
  };

  bridgeModule = {
    options = {
      interfaces = mkOption {
        type = listOf str;
        default = [ ];
        description = "Bridge member interfaces.";
      };

      rstp = mkOption {
        type = bool;
        default = false;
        description = "Enable RSTP on the bridge.";
      };

      useDHCP = mkOption {
        type = bool;
        default = false;
        description = "Enable DHCP on the bridge interface.";
      };

      ipv4.addresses = mkOption {
        type = listOf (submodule ipAddressModule);
        default = [ ];
        description = "Static IPv4 addresses assigned to the bridge.";
      };

      ipv6.addresses = mkOption {
        type = listOf (submodule ipAddressModule);
        default = [ ];
        description = "Static IPv6 addresses assigned to the bridge.";
      };

      mtu = mkOption {
        type = nullOr int;
        default = null;
        description = "Bridge MTU.";
      };

      macAddress = mkOption {
        type = nullOr str;
        default = null;
        description = "Bridge MAC address.";
      };
    };
  };
in
{
  imports = [
    inputs.proxmox-nixos.nixosModules.proxmox-ve
  ];

  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = mkEnableOption appName;

      ipAddress = mkOption {
        type = str;
        default = config.homelab.host.address;
        description = "Primary IP address used by Proxmox VE.";
      };

      openFirewall = mkOption {
        type = bool;
        default = true;
        description = "Open Proxmox VE firewall ports.";
      };

      bridges = mkOption {
        type = attrsOf (submodule bridgeModule);
        default = { };
        description = "Host bridge configuration managed by the feature.";
      };

      vms = mkOption {
        type = attrsOf anything;
        default = { };
        description = ''
          Declarative VM definitions forwarded to `services.proxmox-ve.vms`.
        '';
      };
    };
  };

  config = mkMerge [
    {
      homelab.features.${appName}.appInfos = {
        category = appCategory;
        displayName = appDisplayName;
        icon = appIcon;
        platform = appPlatform;
        description = appDescription;
        url = appUrl;
        pinnedVersion = appPinnedVersion;
        serviceURL = exposedURL;
      };
    }

    (mkIf cfg.enable {
      nixpkgs.overlays = [
        inputs.proxmox-nixos.overlays.${system}
      ];

      services.proxmox-ve = {
        enable = true;
        ipAddress = cfg.ipAddress;
        openFirewall = cfg.openFirewall;
        bridges = attrNames cfg.bridges;
        vms = cfg.vms;
      };

      networking.bridges = mapAttrs (_: bridge: {
        inherit (bridge)
          interfaces
          rstp
          ;
      }) cfg.bridges;

      networking.interfaces = mapAttrs (_: bridge: {
        useDHCP = bridge.useDHCP;
        inherit (bridge) mtu;
        ipv4.addresses = bridge.ipv4.addresses;
        ipv6.addresses = bridge.ipv6.addresses;
      } // optionalAttrs (bridge.macAddress != null) {
        macAddress = bridge.macAddress;
      }) cfg.bridges;
    })
  ];
}
