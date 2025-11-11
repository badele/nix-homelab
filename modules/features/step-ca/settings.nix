{
  config,
  appName,
  ...
}:
let
  cfg = config.homelab.features.${appName};
in
{
  root = "/home/step/certs/root_ca.crt";
  crt = "/home/step/certs/intermediate_ca.crt";
  key = "/home/step/secrets/intermediate_ca_key";
  address = ":9000";
  dnsNames = [
    cfg.serviceDomain
  ];
  logger = {
    format = "text";
  };
  db = {
    type = "badgerv2";
    dataSource = "/home/step/db";
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
