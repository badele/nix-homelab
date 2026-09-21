{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  resolveListenInterfaceAddresses,
  ...
}:
with lib;
with types;

let
  appName = "openssh";
  appDisplayName = "OpenSSH";
  appCategory = "Core Services";
  appIcon = "sh-openssh";
  appPlatform = "nixos";
  appDescription = "${pkgs.openssh.meta.description}";
  appUrl = pkgs.openssh.meta.homepage;
  appPinnedVersion = pkgs.openssh.version;

  cfg = config.homelab.features.${appName};
  primaryPort = head config.services.openssh.ports;
  listenAddresses = resolveListenInterfaceAddresses appName cfg.listenInterfaces;
  requiredListenAddresses = escapeShellArgs listenAddresses;
  tunnelClientUser = "openssh-tunnel";
  tunnelClientGroup = "openssh-tunnel";
  tunnelClientHome = "/var/lib/openssh-tunnel";

  # Wait interfaces to be up before starting sshd, otherwise it may fail to bind to the listen addresses.
  waitForListenAddresses = pkgs.writeShellScript "wait-for-openssh-listen-addresses" ''
    timeout=120

    while [ "$timeout" -gt 0 ]; do
      missing=0

      for address in ${requiredListenAddresses}; do
        if ! ${pkgs.iproute2}/bin/ip -o -4 addr show | ${pkgs.gnugrep}/bin/grep -Fq " inet ''${address}/"; then
          echo "Waiting for OpenSSH listen address ''${address}"
          missing=1
        fi
      done

      if [ "$missing" -eq 0 ]; then
        exit 0
      fi

      timeout=$((timeout - 1))
      sleep 1
    done

    echo "Timed out waiting for OpenSSH listen addresses: ${requiredListenAddresses}" >&2
    exit 1
  '';

  # Convert resolved listen addresses plus SSH ports to the shape expected by
  # services.openssh.listenAddresses.
  sshListenAddresses = flatten (
    map (
      address:
      map (port: {
        addr = address;
        port = port;
      }) config.services.openssh.ports
    ) listenAddresses
  );
  exposedURL = "ssh://${cfg.serviceDomain}:${toString primaryPort}";

  # Client-side option, usually on a private instance. One local forward maps a
  # listener on the client machine to an address reachable from the SSH server
  # side.
  # Example: 127.0.0.1:11252 on the private client forwards to 127.0.0.1:10252
  # as seen from the public SSH server.
  tunnelForwardOptions = {
    options = {
      localAddress = mkOption {
        type = str;
        default = "127.0.0.1";
        description = "Local address used by the SSH tunnel listener.";
      };

      localPort = mkOption {
        type = port;
        description = "Local port used by the SSH tunnel listener.";
      };

      remoteAddress = mkOption {
        type = str;
        default = "127.0.0.1";
        description = "Remote address reached from the SSH server side.";
      };

      remotePort = mkOption {
        type = port;
        description = "Remote port reached from the SSH server side.";
      };
    };
  };

  # Client-side declaration, usually on a private instance. The client initiates
  # the SSH connection to a reachable SSH server, often a public instance. When
  # identityFile is not set, the module derives a Clan vars keypair from
  # keyGeneratorName.
  # Example: a private client declares a tunnel to a public server and gets a
  # systemd service plus a private key deployed locally.
  tunnelOptions =
    { name, ... }:
    {
      options = {
        enable = mkEnableOption "OpenSSH local tunnel";

        targetHost = mkOption {
          type = str;
          default = name;
          description = "Logical target host name for this tunnel.";
        };

        targetAddress = mkOption {
          type = str;
          description = "SSH server address used by this tunnel.";
        };

        targetPort = mkOption {
          type = port;
          default = 22;
          description = "SSH server port used by this tunnel.";
        };

        targetUser = mkOption {
          type = str;
          description = "SSH user used by this tunnel.";
        };

        identityFile = mkOption {
          type = nullOr path;
          default = null;
          description = "Existing private SSH key used by this tunnel. If unset, a Clan vars key is generated.";
        };

        keyGeneratorName = mkOption {
          type = nullOr str;
          default = "openssh-tunnel-${config.networking.hostName}-${name}";
          description = "Clan vars generator name used to create this tunnel keypair.";
        };

        forwards = mkOption {
          type = listOf (submodule [ tunnelForwardOptions ]);
          default = [ ];
          description = "Local forwards opened by this tunnel.";
        };
      };
    };

  # Server-side declaration, usually on a public instance. The SSH server accepts
  # the incoming tunnel connection and exposes only the permitted remote targets
  # to the client.
  # Example: a public server declares metrics-tunnel and only allows it to open
  # selected 127.0.0.1:<port> destinations.
  tunnelUserOptions =
    { name, ... }:
    {
      options = {
        enable = mkEnableOption "restricted OpenSSH tunnel user";

        user = mkOption {
          type = str;
          default = name;
          description = "System user created for restricted SSH tunnels.";
        };

        group = mkOption {
          type = str;
          default = name;
          description = "System group created for restricted SSH tunnels.";
        };

        home = mkOption {
          type = str;
          default = "/var/lib/${name}";
          description = "Home directory for the restricted SSH tunnel user.";
        };

        authorizedKeys = mkOption {
          type = listOf str;
          default = [ ];
          description = "SSH public keys allowed for this restricted tunnel user.";
        };

        authorizedKeyGenerators = mkOption {
          type = listOf str;
          default = [ ];
          description = "Clan vars generator names whose public keys are allowed for this tunnel user.";
        };

        permitOpen = mkOption {
          type = listOf str;
          default = [ ];
          description = "Remote host:port pairs this tunnel user may open.";
        };
      };
    };

  # Client-side declarations enabled on this machine.
  enabledTunnels = filterAttrs (_: tunnelCfg: tunnelCfg.enable) cfg.tunnels;

  # Server-side declarations enabled on this machine.
  enabledTunnelUsers = filterAttrs (_: userCfg: userCfg.enable) cfg.tunnelUsers;
  enabledTunnelValues = attrValues enabledTunnels;

  # Client-side key names required by outgoing tunnels on this machine. These
  # machines need the private key at runtime.
  generatedTunnelKeyNames = lib.unique (
    filter (generatorName: generatorName != null) (
      map (
        tunnelCfg: if tunnelCfg.identityFile == null then tunnelCfg.keyGeneratorName else null
      ) enabledTunnelValues
    )
  );

  # Server-side key names trusted by restricted tunnel users on this machine.
  # These machines only need the public key at runtime.
  authorizedKeyGeneratorNames = lib.unique (
    concatMap (userCfg: userCfg.authorizedKeyGenerators) (attrValues enabledTunnelUsers)
  );

  # Shared Clan generators are role-neutral and must have identical definitions
  # on every client/server machine that references them. Deployment therefore
  # happens through local client/server generators below, not directly from the
  # shared generator.
  # This union is the set of logical keypairs that must exist in Clan vars.
  tunnelKeyGeneratorNames = lib.unique (generatedTunnelKeyNames ++ authorizedKeyGeneratorNames);

  # Local deployment generators are intentionally suffixed so they are not shared
  # between machines. The client wrapper deploys the private key, while the
  # server wrapper deploys the public key.
  mkClientTunnelKeyGeneratorName = generatorName: "${generatorName}-client";
  mkServerTunnelKeyGeneratorName = generatorName: "${generatorName}-server";

  # Shared generator: role-neutral Clan source that creates the keypair once and
  # exposes it to dependent client/server generators, but deploys neither file
  # directly to any machine.
  mkSharedTunnelKeyGenerator =
    generatorName:
    nameValuePair generatorName {
      share = true;

      files = {
        "id_ed25519" = {
          secret = true;
          deploy = false;
        };

        "id_ed25519.pub" = {
          secret = false;
          deploy = false;
        };
      };

      runtimeInputs = [ pkgs.openssh ];

      script = ''
        ssh-keygen -q -N "" -t ed25519 -C "${generatorName}" -f "$out/id_ed25519"
      '';
    };

  # Client-local generator, usually on a private instance: copies only the
  # private key from the shared generator and deploys it on the tunnel initiator.
  # For constellation -> cab1e, this creates ...-client/id_ed25519 on
  # constellation only.
  mkClientTunnelKeyGenerator =
    generatorName:
    nameValuePair (mkClientTunnelKeyGeneratorName generatorName) {
      dependencies = [ generatorName ];

      files."id_ed25519" = {
        secret = true;
        deploy = true;
        owner = tunnelClientUser;
        group = tunnelClientGroup;
        mode = "0400";
      };

      script = ''
        cp "$in/${generatorName}/id_ed25519" "$out/id_ed25519"
      '';
    };

  # Server-local generator, usually on a public instance: copies only the public
  # key from the shared generator and deploys it on the SSH server that accepts
  # the tunnel.
  # For constellation -> cab1e, this creates ...-server/id_ed25519.pub on cab1e
  # only.
  mkServerTunnelKeyGenerator =
    generatorName:
    nameValuePair (mkServerTunnelKeyGeneratorName generatorName) {
      dependencies = [ generatorName ];

      files."id_ed25519.pub" = {
        secret = false;
        deploy = true;
      };

      script = ''
        cp "$in/${generatorName}/id_ed25519.pub" "$out/id_ed25519.pub"
      '';
    };

  mkVarsFilePath = generatorName: fileName: "/run/secrets/vars/${generatorName}/${fileName}";
  authorizedKeysCommandPath = "/run/openssh-tunnel-authorized-keys";

  # Client-side runtime: the tunnel runs as a long-lived systemd service on the
  # machine that initiates the SSH connection. ExitOnForwardFailure makes a failed
  # bind/connect visible immediately instead of leaving a useless service.
  # The script uses escapeShellArgs so forward definitions remain safe to render
  # as command-line arguments.
  mkTunnelScript =
    tunnelName: tunnelCfg:
    let
      identityFile =
        if tunnelCfg.identityFile != null then
          tunnelCfg.identityFile
        else
          mkVarsFilePath (mkClientTunnelKeyGeneratorName tunnelCfg.keyGeneratorName) "id_ed25519";
      forwardArgs = concatMap (forward: [
        "-L"
        "${forward.localAddress}:${toString forward.localPort}:${forward.remoteAddress}:${toString forward.remotePort}"
      ]) tunnelCfg.forwards;
      sshArgs = [
        "-N"
        "-T"
        "-o"
        "BatchMode=yes"
        "-o"
        "PasswordAuthentication=no"
        "-o"
        "KbdInteractiveAuthentication=no"
        "-o"
        "ExitOnForwardFailure=yes"
        "-o"
        "ServerAliveInterval=30"
        "-o"
        "ServerAliveCountMax=3"
        "-o"
        "StrictHostKeyChecking=accept-new"
        "-o"
        "UserKnownHostsFile=${tunnelClientHome}/known_hosts"
        "-i"
        "${identityFile}"
        "-p"
        (toString tunnelCfg.targetPort)
      ]
      ++ forwardArgs
      ++ [
        "${tunnelCfg.targetUser}@${tunnelCfg.targetAddress}"
      ];
    in
    pkgs.writeShellScript "openssh-tunnel-${tunnelName}" ''
      exec ${pkgs.openssh}/bin/ssh ${escapeShellArgs sshArgs}
    '';

  # Client-side runtime: turn each outgoing tunnel declaration into one systemd
  # service. The service name is stable and follows openssh-tunnel-<tunnelName>.
  mkTunnelServiceName = tunnelName: "openssh-tunnel-${tunnelName}";

  mkTunnelService =
    tunnelName: tunnelCfg:
    nameValuePair (mkTunnelServiceName tunnelName) {
      description = "OpenSSH tunnel ${tunnelName} to ${tunnelCfg.targetHost}";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = tunnelClientUser;
        Group = tunnelClientGroup;
        StateDirectory = tunnelClientUser;
        ExecStart = mkTunnelScript tunnelName tunnelCfg;
        Restart = "always";
        RestartSec = "10s";
      };
    };

  # Client-side aliases, usually on a private instance. The config alias prints
  # the generated tunnel script referenced by ExecStart.
  mkTunnelAliases =
    tunnelName: _: {
      "@service-openssh-tunnel-${tunnelName}-journal" = "journalctl -u ${mkTunnelServiceName tunnelName}";
      "@service-openssh-tunnel-${tunnelName}-start" = "systemctl start ${mkTunnelServiceName tunnelName}";
      "@service-openssh-tunnel-${tunnelName}-stop" = "systemctl stop ${mkTunnelServiceName tunnelName}";
      "@service-openssh-tunnel-${tunnelName}-restart" = "systemctl restart ${mkTunnelServiceName tunnelName}";
      "@service-openssh-tunnel-${tunnelName}-status" = "systemctl status ${mkTunnelServiceName tunnelName}";
      "@service-openssh-tunnel-${tunnelName}-config" =
        "cat $(systemctl cat ${mkTunnelServiceName tunnelName} | grep -oP \"^ExecStart=\\K.*\")";
    };

  # Server-side aliases, usually on a public instance. Restricted tunnel users
  # are enforced by sshd, so these aliases manage the global sshd service.
  mkTunnelUserAliases =
    userName: _: {
      "@service-openssh-tunnel-user-${userName}-journal" = "journalctl -u sshd";
      "@service-openssh-tunnel-user-${userName}-start" = "systemctl start sshd";
      "@service-openssh-tunnel-user-${userName}-stop" = "systemctl stop sshd";
      "@service-openssh-tunnel-user-${userName}-restart" = "systemctl restart sshd";
      "@service-openssh-tunnel-user-${userName}-status" = "systemctl status sshd";
      "@service-openssh-tunnel-user-${userName}-config" = "systemctl cat sshd";
    };

  # Server-side enforcement: key-level restrictions used for inline
  # authorizedKeys. Generated keys get the same text from AuthorizedKeysCommand.
  mkRestrictedKeyOptions =
    userCfg:
    let
      permitOpenOptions = map (permitOpen: ''permitopen="${permitOpen}"'') userCfg.permitOpen;
    in
    concatStringsSep "," (
      [
        "restrict"
        "port-forwarding"
      ]
      ++ permitOpenOptions
    );

  mkRestrictedKey = userCfg: key: "${mkRestrictedKeyOptions userCfg} ${key}";

  # Server-side authentication: NixOS authorizedKeys.keyFiles uses lib.readFile
  # at build time, so it cannot point at /run/secrets/vars. AuthorizedKeysCommand
  # reads the Clan-provided public key path at SSH authentication time instead.
  # The command prints authorized_keys lines with restrictions prepended, based
  # on the requested SSH user.
  mkGeneratedAuthorizedKeysCommand =
    let
      mkKeyFilePrinter =
        userCfg: generatorName:
        let
          keyOptions = escapeShellArg (mkRestrictedKeyOptions userCfg);
          serverGeneratorName = mkServerTunnelKeyGeneratorName generatorName;
          keyFile = escapeShellArg config.clan.core.vars.generators.${serverGeneratorName}.files."id_ed25519.pub".path;
        in
        ''
          if [ -r ${keyFile} ]; then
            while IFS= read -r key; do
              if [ -n "$key" ]; then
                printf '%s %s\n' ${keyOptions} "$key"
              fi
            done < ${keyFile}
          fi
        '';
      mkUserCase =
        _: userCfg:
        optionalString (userCfg.authorizedKeyGenerators != [ ]) ''
          ${escapeShellArg userCfg.user})
            ${concatStringsSep "\n" (map (mkKeyFilePrinter userCfg) userCfg.authorizedKeyGenerators)}
            ;;
        '';
    in
    pkgs.writeShellScript "openssh-tunnel-authorized-keys" ''
      set -euo pipefail

      case "''${1:-}" in
      ${concatStringsSep "\n" (mapAttrsToList mkUserCase enabledTunnelUsers)}
        *)
          ;;
      esac
    '';

  # Server-side enforcement: Match blocks restrict the SSH account that accepts
  # tunnel connections. Inline authorizedKeys still get key-level restrictions
  # from mkRestrictedKey.
  # This complements key-level restrictions and also covers generated keys read
  # through AuthorizedKeysCommand.
  mkTunnelUserMatchBlock = _: userCfg: ''
    Match User ${userCfg.user}
      AllowTcpForwarding local
      PermitOpen ${concatStringsSep " " userCfg.permitOpen}
      PermitTTY no
      X11Forwarding no
      AllowAgentForwarding no
      PasswordAuthentication no
  '';
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = mkEnableOption appName;

      serviceDomain = mkOption {
        type = str;
        default = "ssh.${config.homelab.domain}";
        description = "${appName} service domain name";
      };

      openFirewall = mkEnableOption "Open firewall ports (incoming)";

      tunnels = mkOption {
        type = attrsOf (submodule tunnelOptions);
        default = { };
        description = "OpenSSH local tunnels started from this machine.";
      };

      tunnelUsers = mkOption {
        type = attrsOf (submodule tunnelUserOptions);
        default = { };
        description = "Restricted local users allowed to terminate SSH tunnels.";
      };
    };
  };

  ############################################################################
  # Configuration
  ############################################################################
  config = mkMerge [
    {
      homelab.features.${appName} = {
        appInfos = {
          category = appCategory;
          displayName = appDisplayName;
          icon = appIcon;
          platform = appPlatform;
          description = appDescription;
          url = appUrl;
          pinnedVersion = appPinnedVersion;
          serviceURL = exposedURL;
        };
      };
    }

    (mkIf cfg.enable {
      assertions =
        (mapAttrsToList (tunnelName: tunnelCfg: {
          assertion = tunnelCfg.forwards != [ ];
          message = "homelab.features.openssh.tunnels.${tunnelName}.forwards must contain at least one forward.";
        }) enabledTunnels)
        ++ (mapAttrsToList (tunnelName: tunnelCfg: {
          assertion = tunnelCfg.identityFile != null || tunnelCfg.keyGeneratorName != null;
          message = "homelab.features.openssh.tunnels.${tunnelName}.identityFile or keyGeneratorName must be set.";
        }) enabledTunnels)
        ++ (mapAttrsToList (userName: userCfg: {
          assertion = userCfg.authorizedKeys != [ ] || userCfg.authorizedKeyGenerators != [ ];
          message = "homelab.features.openssh.tunnelUsers.${userName}.authorizedKeys or authorizedKeyGenerators must contain at least one key.";
        }) enabledTunnelUsers)
        ++ (mapAttrsToList (userName: userCfg: {
          assertion = userCfg.permitOpen != [ ];
          message = "homelab.features.openssh.tunnelUsers.${userName}.permitOpen must contain at least one host:port pair.";
        }) enabledTunnelUsers);

      services.openssh = {
        enable = true;
        openFirewall = false;
        listenAddresses = sshListenAddresses;
        extraConfig = concatStringsSep "\n" (mapAttrsToList mkTunnelUserMatchBlock enabledTunnelUsers);
        authorizedKeysCommand = mkIf (authorizedKeyGeneratorNames != [ ]) "${authorizedKeysCommandPath} %u";
        authorizedKeysCommandUser = mkIf (authorizedKeyGeneratorNames != [ ]) "root";
      };

      programs.bash.shellAliases =
        (foldl' recursiveUpdate { } (mapAttrsToList mkTunnelAliases enabledTunnels))
        // (foldl' recursiveUpdate { } (mapAttrsToList mkTunnelUserAliases enabledTunnelUsers));

      # Declare the shared keypair plus the local deployment generators required
      # by this machine's role in each tunnel: private key on the client, public
      # key on the server.
      clan.core.vars.generators = listToAttrs (
        (map mkSharedTunnelKeyGenerator tunnelKeyGeneratorNames)
        ++ (map mkClientTunnelKeyGenerator generatedTunnelKeyNames)
        ++ (map mkServerTunnelKeyGenerator authorizedKeyGeneratorNames)
      );

      systemd.services = (mapAttrs' mkTunnelService enabledTunnels) // {
        sshd = mkIf (cfg.listenInterfaces != [ ]) {
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            ExecStartPre = [ waitForListenAddresses ];
            RestartSec = "10s";
          };
        };
      };

      system.activationScripts = mkIf (authorizedKeyGeneratorNames != [ ]) {
        # Server-side authentication: OpenSSH refuses AuthorizedKeysCommand when
        # any path component is group-writable. Copy the generated script outside
        # /nix/store so sshd accepts it under StrictModes.
        opensshTunnelAuthorizedKeysCommand.text = ''
          install -D -o root -g root -m 0500 ${mkGeneratedAuthorizedKeysCommand} ${authorizedKeysCommandPath}
        '';
      };

      users.groups =
        optionalAttrs (enabledTunnels != { }) {
          ${tunnelClientGroup} = { };
        }
        // mapAttrs' (_: userCfg: nameValuePair userCfg.group { }) enabledTunnelUsers;

      users.users =
        optionalAttrs (enabledTunnels != { }) {
          ${tunnelClientUser} = {
            isSystemUser = true;
            group = tunnelClientGroup;
            home = tunnelClientHome;
            createHome = true;
            shell = "${pkgs.shadow}/bin/nologin";
          };
        }
        // mapAttrs' (
          _: userCfg:
          nameValuePair userCfg.user {
            isSystemUser = true;
            group = userCfg.group;
            home = userCfg.home;
            createHome = true;
            shell = "${pkgs.shadow}/bin/nologin";
            openssh.authorizedKeys.keys = map (mkRestrictedKey userCfg) userCfg.authorizedKeys;
          }
        ) enabledTunnelUsers;

      networking.firewall.interfaces = mkIf cfg.openFirewall (
        lib.genAttrs cfg.listenInterfaces (_: {
          allowedTCPPorts = config.services.openssh.ports;
        })
      );
    })
  ];
}
