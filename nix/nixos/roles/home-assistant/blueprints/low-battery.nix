{ pkgs, config, fetchgit, ... }:
let
  # TODO: move to pkgs libraries
  hacs-low-battery-level = pkgs.stdenv.mkDerivation
    rec {
      pname = "hacs-low-battery-level";
      version = "rev9";
      src = pkgs.fetchgit {
        url = "https://gist.github.com/sbyx/1f6f434f0903b872b84c4302637d0890";
        sha256 = "GhFVqrcjP++v6T7w6gvjMUiULHILksT+OJua+MHmfZw=";
      };

      installPhase = ''
        mkdir -p "$out/sbyx"
        install -Dm444 "${src}/low-battery-level-detection-notification-for-all-battery-sensors.yaml" "$out/sbyx/"
      '';
    };

in
{
  systemd.tmpfiles.rules = [
    "L  /var/lib/hass/blueprints/automation/sbyx 770    ${config.users.users.hass.name} ${config.users.users.hass.group}    -   ${hacs-low-battery-level}/sbyx"
  ];
}
