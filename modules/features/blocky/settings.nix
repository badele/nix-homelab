{
  # these external DNS resolvers will be used. Blocky picks 2 random resolvers from the list for each query
  # format for resolver: [net:]host:[port][/path]. net could be empty (default, shortcut for tcp+udp),
  # tcp+udp, tcp, udp, tcp-tls or https (DoH). If port is empty, default port will be used
  # (53 for udp and tcp, 853 for tcp-tls, 443 for https (Doh))
  # this configuration is mandatory, please define at least one external DNS resolver
  #
  # https://www.privacyguides.org/en/dns
  # https://dnsprivacy.org/public_resolvers
  # https://www.joindns4.eu/for-public
  bootstrapDns = [
    "9.9.9.9"
    "1.1.1.1"
  ];

  upstreams = {
    groups = {
      default = [
        "9.9.9.9"
        "149.112.112.112"
        "https://dns.quad9.net/dns-query"
        "tcp-tls:dns.quad9.net"
      ];
    };
  };

  blocking = {
    denylists = {
      ads = [
        "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
        "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro.txt"
      ];
      fakenews = [
        "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-only/hosts"
      ];
      gambling = [
        "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-only/hosts"
      ];
      adult = [
        "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-only/hosts"
      ];
    };

    clientGroupsBlock = {
      default = [
        "ads"
        "fakenews"
        "gambling"
        "adult"
      ];
    };
  };
}
