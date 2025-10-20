{
  lib,
  config,
  ...
}:
let
  ignore_ip = [
    "127.0.0.1"
    "::1"
    "90.113.129.48"
  ];

  ban_scan = 24 * 7;

  sudo = "/run/wrappers/bin/sudo";
  ip4tables = "${config.networking.firewall.package}/bin/iptables";
  ip6tables = "${config.networking.firewall.package}/bin/ip6tables";
in
{
  # Source: https://framagit.org/ppom/nixos/-/blob/main/modules/common/reaction-custom.nix
  config =
    let
      iptablesBan = cmd: [
        sudo
        cmd
        "-w"
        "-A"
        "reaction"
        "-s"
        "<ip>"
        "-j"
        "DROP"
      ];
      iptablesUnban = cmd: [
        sudo
        cmd
        "-w"
        "-D"
        "reaction"
        "-s"
        "<ip>"
        "-j"
        "DROP"
      ];

      banFor = duration: {
        ban4 = {
          cmd = iptablesBan ip4tables;
          ipv4only = true;
        };
        ban6 = {
          cmd = iptablesBan ip6tables;
          ipv6only = true;
        };

        unban4 = {
          cmd = iptablesUnban ip4tables;
          ipv4only = true;
          after = duration;
        };
        unban6 = {
          cmd = iptablesUnban ip6tables;
          ipv6only = true;
          after = duration;
        };
      };
    in
    {
      users.users.reaction = {
        extraGroups = [
          "systemd-journal"
          "vector"
        ];
      };

      # Allow reaction to manage iptables rules
      security.sudo.execWheelOnly = lib.mkForce false;
      security.sudo.extraRules = [
        {
          users = [ "reaction" ];
          commands = [
            {
              command = "${config.networking.firewall.package}/bin/iptables";
              options = [
                "NOPASSWD"
              ];
            }
            {
              command = "${config.networking.firewall.package}/bin/ip6tables";
              options = [
                "NOPASSWD"
              ];
            }
          ];

          runAs = "root";
        }
      ];

      services.reaction = {
        enable = true;
        runAsRoot = false;
        settings = {
          patterns = {
            ip = {
              type = "ip";
              ipv6mask = 64;
              ignore = ignore_ip;
            };
          };

          streams = {
            vector = {
              cmd = [
                "tail"
                "-n0"
                "-F"
                "/var/lib/vector/logs/reaction.logfmt"
              ];

              filters = {
                port_scan = {
                  regex = [
                    "ip=<ip>.*risk_type=.?port scan.?.*service=iptables"
                  ];
                  retry = 3;
                  retryperiod = "4h";
                  actions = banFor "${toString (ban_scan)}h";
                };
                login_fail = {
                  regex = [
                    "ip=<ip>.*risk_type=.?login fail.*service=sshd"
                  ];
                  retry = 3;
                  retryperiod = "4h";
                  actions = banFor "${toString (ban_scan)}h";
                };
                ddos = {
                  regex = [
                    "ip=<ip>.*risk_type=DDOS.*service=sshd"
                  ];
                  retry = 3;
                  retryperiod = "4h";
                  actions = banFor "${toString (ban_scan)}h";
                };
                http_exploit = {
                  regex = [
                    "ip=<ip>.*risk_type=.?HTTP exploit.?.*service=nginx_logs"
                  ];
                  retry = 2;
                  retryperiod = "4h";
                  actions = banFor "${toString (ban_scan)}h";
                };
                ai_bot = {
                  regex = [
                    "ip=<ip>.*risk_type=.?AI bot.?.*service=nginx_logs"
                  ];
                  retry = 2;
                  retryperiod = "4h";
                  actions = banFor "${toString (ban_scan)}h";
                };
              };
            };
          };
        };
      };

      # Create the reaction chain in iptables when the service starts
      systemd.services.reaction = {
        serviceConfig =
          let

            mkIptablesCmd = table: args: "+${sudo} ${table} ${args}";

            ip46tables = args: [
              (mkIptablesCmd ip4tables args)
              (mkIptablesCmd ip6tables args)
            ];
          in
          {
            ExecStartPre = builtins.concatMap ip46tables [
              "-w -N reaction"
              "-w -I INPUT -p all -j reaction"
              "-w -I FORWARD -p all -j reaction"
            ];
            ExecStopPost = builtins.concatMap ip46tables [
              "-w -D INPUT -p all -j reaction"
              "-w -D FORWARD -p all -j reaction"
              "-w -F reaction"
              "-w -X reaction"
            ];
            TimeoutStopSec = "3min";
            UMask = "0002";
          };
      };

      # Verify that the reaction chain exists in iptables every 10 minutes
      systemd.services.reaction-chain =
        let

          message = chain: "reaction chain has been removed from ${chain} :o";
        in
        {
          enable = true;
          startAt = "*:0/10";
          unitConfig.Requisite = [ "reaction.service" ];
          script = ''
            if ! ${sudo} ${ip4tables} -L INPUT | grep -q reaction
            then
              ${sudo} ${ip4tables} -w -I INPUT -p all -j reaction
              echo ${message "INPUT"}
            fi

            if ! ${sudo} ${ip4tables} -L FORWARD | grep -q reaction
            then
              ${sudo} ${ip4tables} -w -I FORWARD -p all -j reaction
              echo ${message "FORWARD"}
            fi
          '';
        };
    };
}
