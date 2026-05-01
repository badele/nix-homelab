{ inputs }:
[
  # Radio package from external flake input
  (
    final: prev:
    prev.lib.optionalAttrs (inputs ? radio) {
      radio = inputs.radio.packages.${final.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
        meta = (old.meta or { }) // {
          mainProgram = "radio";
        };
      });
    }
  )
]
