{ config, pkgs, ... }:
let

  snmpFile = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/prometheus/snmp_exporter/main/snmp.yml";
    sha256 = "sha256:0cshh89ijchi10iqijvmw473hhxf5cdrd1y0502wlwgw4glbis36";
  };

  mikrotikMib =
    builtins.replaceStrings [
      "mikrotik:"
    ] [
      ''
        mikrotik:
          version: 2
          auth:
            community: public
      ''
    ]
      (builtins.readFile snmpFile);

  snmpConf = pkgs.writeText "snmp.yaml" ''
    ${mikrotikMib}
  '';

in
{
  services.prometheus = {
    exporters = {
      snmp = {
        enable = true;
        configurationPath = snmpConf;
      };
    };
  };
}


