{

  inputs,
  pkgs,
  ...
}:
let
  user = "sadele";
in
{
  programs.firefox = {
    enable = true;

    # Search firefox extension
    #https://nur.nix-community.org/repos/rycee/
    profiles."${user}".extensions.packages =
      with inputs.nur.legacyPackages.${pkgs.stdenv.hostPlatform.system}.repos.rycee.firefox-addons; [
        behind-the-overlay-revival # Block overlay mask
        simple-translate # Translate
        ublock-origin # addblocker

        # Install manually addons
        # On addon website, get download link of the addon (install/uninstall button)
        # Fromt firefox (about:support) copy the addonId

        # - https://addons.mozilla.org/firefox/downloads/file/4528991/francais_language_pack-140.0.20250707.120347.xpi
        # - https://addons.mozilla.org/firefox/downloads/file/3581786/dictionnaire_francais1-7.0b.xpi

        # LanguageTool, grammar and spell checker
        (buildFirefoxXpiAddon rec {
          pname = "languagetool";
          version = "8.3.0";
          addonId = "languagetool-webextension@languagetool.org";
          url = "https://addons.mozilla.org/firefox/downloads/file/4199245/languagetool-${version}.xpi";
          sha256 = "sha256-41dCTj353eS6EOufjzcZrEgwaBVwVX9NUdsVpGLNdmc=";
          meta = { };
        })

      ];

  };

  home.packages = with pkgs; [
  ];
}
