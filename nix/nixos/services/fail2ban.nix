{ ... }: {
  # fail2ban cheat
  # cat /var/lib/traefik/access.log
  # fail2ban-client status
  # fail2ban-client status traefik
  #
  # fail2ban-regex /var/lib/traefik/access.log /etc/fail2ban/filter.d/traefik.conf
  # fail2ban-regex /var/lib/traefik/access.log '^<HOST> - .* "(GET|POST|HEAD).*" (404|444|403|400) .*$'
  #
  # ban
  # fail2ban-client set <JAIL> banip <IP>
  # unban
  # fail2ban-client set <JAIL> unbanip <IP>

  services.fail2ban = {
    enable = true;
    # Ban IP after 2 failures
    ignoreIP = [ "192.168.254.0/24" ];
    maxretry = 3;
    bantime = "12h";
    jails = {
      traefik = ''
        enabled  = true
        port     = http,https
        filter   = traefik
        logpath  = /var/lib/traefik/access.log
      '';
    };
  };

  # traefik filter
  environment.etc."fail2ban/filter.d/traefik.conf".text = ''
    [Definition]
    failregex = ^<HOST> - .* "(GET|POST|HEAD).*" (404|444|403|400) .*$
    ignoreregex =
    pollinterval = 3s
    findtime = 1h
  '';
}
