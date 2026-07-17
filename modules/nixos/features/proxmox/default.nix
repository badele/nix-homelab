{
  config,
  lib,
  pkgs,
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
  cfg = config.homelab.features.${appName};
  system = config.nixpkgs.hostPlatform.system;
  # Read the package version from the flake input directly so documentation
  appPinnedVersion = lib.getVersion inputs.proxmox-nixos.packages.${system}.proxmox-ve;
  exposedURL = "https://${cfg.ipAddress}:8006";
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
        bridges = attrNames config.networking.bridges;
        vms = cfg.vms;
      };
    })
  ];
}
