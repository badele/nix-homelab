{
  config,
  appName,
  ...
}:
let
  cfg = config.homelab.features.${appName};
  secrets = config.clan.core.vars.generators;

in
{
  root = secrets.step-ca-root-ca.files."root-ca.crt".path;
  crt = secrets.step-ca-intermediate-ca.files."intermediate-ca.crt".path;
  key = secrets.step-ca-intermediate-ca.files."intermediate-ca.key".path;
  dnsNames = [
    cfg.serviceDomain
  ];
  logger = {
    format = "text";
  };
  db = {
    type = "badgerv2";
    dataSource = "/var/lib/step-ca/db";
  };
  authority = {
    provisioners = [
      {
        type = "ACME";
        name = "acme";
      }
    ];
  };
  tls = {
    cipherSuites = [
      "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
      "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
    ];
    minVersion = 1.2;
    maxVersion = 1.3;
  };
}
