{ inputs }:
[
  # Radio package from external flake input
  (final: prev: {
    radio = inputs.radio.packages.${final.system}.default;
  })

  (final: prev: {
    reaction = prev.rustPlatform.buildRustPackage rec {
      pname = "reaction";
      version = "2.2.0";

      src = prev.fetchFromGitLab {
        domain = "framagit.org";
        owner = "ppom";
        repo = "reaction";
        rev = "v${version}";
        hash = "sha256-TVxBW47GqnfP8K8ZcjSR0P84dnb8Z5c3o11Ql5wsvLg=";
      };

      cargoHash = "sha256-ACacxDbJjbv7sP1D0wO6vjCVhlPui1ogXZKxY5l+3JU=";

      postBuild = ''
        $CC helpers_c/ip46tables.c -o ip46tables
        $CC helpers_c/nft46.c -o nft46
      '';

      postInstall = ''
        cp ip46tables nft46 $out/bin
      '';

      meta = with prev.lib; {
        description = "Scan logs and take action: an alternative to fail2ban";
        homepage = "https://framagit.org/ppom/reaction";
        changelog = "https://framagit.org/ppom/reaction/-/releases/v${version}";
        license = licenses.agpl3Plus;
        mainProgram = "reaction";
        maintainers = with maintainers; [ ppom ];
        platforms = platforms.unix;
      };
    };
  })
]
