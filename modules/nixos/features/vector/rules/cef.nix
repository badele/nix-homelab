{ cfg, listenAddresses, ... }:
let
  sourceNameForAddress =
    address: "cef_udp_${builtins.replaceStrings [ "." ":" ] [ "_" "_" ] address}";

  sourceNames = map sourceNameForAddress listenAddresses;
in
{
  sources = builtins.listToAttrs (
    map (address: {
      name = sourceNameForAddress address;
      value = {
        type = "socket";
        mode = "udp";
        address = "${address}:${toString cfg.cef.port}";
        decoding.codec = "bytes";
      };
    }) listenAddresses
  );

  transforms = {
    cef_cleaned = {
      type = "remap";
      inputs = sourceNames;
      source = ''
        raw_message = to_string(.message) ?? ""
        socket_host = to_string(.host) ?? "unknown"
        socket_port = to_string(.port) ?? "unknown"

        parsed = parse_cef(raw_message, translate_custom_fields: true) ?? {}
        . = merge(., parsed)

        .message = raw_message
        .service = "cef"
        .transport = "cef"
        .risk_level = "unknown"
        .risk_type = "unknown"

        if exists(.deviceVendor) {
          .vendor = .deviceVendor
        } else {
          .vendor = "unknown"
        }

        if exists(.deviceProduct) {
          .product = .deviceProduct
        } else {
          .product = "unknown"
        }

        if exists(.deviceEventClassId) {
          .event_class = .deviceEventClassId
        } else {
          .event_class = "unknown"
        }

        if exists(.name) {
          .event_name = .name
        } else {
          .event_name = "unknown"
        }

        if exists(.severity) {
          .severity = to_string(.severity)
        } else {
          .severity = "unknown"
        }

        if exists(.source_ip) {
          source_ip, source_ip_err = to_string(.source_ip)
          if source_ip_err == null {
            .source_ip = source_ip
          } else {
            .source_ip = "unknown"
          }
        } else if exists(.src) {
          source_ip, source_ip_err = to_string(.src)
          if source_ip_err == null {
            .source_ip = source_ip
          } else {
            .source_ip = "unknown"
          }
        } else if socket_host != "unknown" {
          .source_ip = socket_host
        } else {
          .source_ip = "unknown"
        }

        .source_host = socket_host
        .source_port = socket_port
        .app_name = .product
      '';
    };
  };

  sinks = { };
}
