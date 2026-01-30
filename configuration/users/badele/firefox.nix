{ pkgs, ... }: {

  # Configure Stylix for Firefox profile
  stylix.targets.firefox.profileNames = [ "badele" ];

  programs.firefox = {
    enable = true;
    profiles.badele = {
      bookmarks = { };
      # Get by about:config and format with https://jsonformatter.org/
      # Use Dark theme
      settings = {
        "browser.tabs.tabMinWidth" = 16;
        "browser.startup.homepage" = "https://www.google.fr/";
        "browser.startup.page" = 3; # Restore previous tabs
        "identity.fxaccounts.enabled" = false;
        "privacy.trackingprotection.enabled" = true;
        "dom.security.https_only_mode" = true;
        "signon.rememberSignons" = false;
        "browser.topsites.blockedSponsors" = ''["amazon"]'';
        "browser.shell.checkDefaultBrowser" = false;
        "browser.shell.defaultBrowserCheckCount" = 1;
        "browser.disableResetPrompt" = true;
        "browser.uiCustomization.state" = ''
          {
            "placements": {
              "widget-overflow-fixed-list": [],
              "unified-extensions-area": [
                "_testpilot-containers-browser-action",
                "tranquility_ushnisha_com-browser-action",
                "craig_wandrer_earth-browser-action"
              ],
              "nav-bar": [
                "back-button",
                "forward-button",
                "stop-reload-button",
                "home-button",
                "urlbar-container",
                "simple-tab-groups_drive4ik-browser-action",
                "browserpass_maximbaz_com-browser-action",
                "_61a05c39-ad45-4086-946f-32adb0a40a9d_-browser-action",
                "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action",
                "_c0e1baea-b4cb-4b62-97f0-278392ff8c37_-browser-action",
                "addon_darkreader_org-browser-action",
                "languagetool-webextension_languagetool_org-browser-action",
                "_0b457caa-602d-484a-8fe7-c1d894a011ba_-browser-action",
                "ublock0_raymondhill_net-browser-action",
                "floccus_handmadeideas_org-browser-action",
                "library-button",
                "downloads-button",
                "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action",
                "simple-translate_sienori-browser-action",
                "_9aa46f4f-4dc7-4c06-97af-5035170634fe_-browser-action",
                "_a1087d5d-d793-445a-b988-088b1d86f2a6_-browser-action",
                "unified-extensions-button",
                "reset-pbm-toolbar-button",
                "_20fc2e06-e3e4-4b2b-812b-ab431220cada_-browser-action"
              ],
              "toolbar-menubar": [
                "menubar-items"
              ],
              "TabsToolbar": [
                "firefox-view-button",
                "tabbrowser-tabs",
                "new-tab-button",
                "alltabs-button"
              ],
              "PersonalToolbar": [
                "import-button",
                "personal-bookmarks"
              ]
            },
            "seen": [
              "save-to-pocket-button",
              "developer-button",
              "ublock0_raymondhill_net-browser-action",
              "_a1087d5d-d793-445a-b988-088b1d86f2a6_-browser-action",
              "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action",
              "floccus_handmadeideas_org-browser-action",
              "simple-tab-groups_drive4ik-browser-action",
              "simple-translate_sienori-browser-action",
              "_9aa46f4f-4dc7-4c06-97af-5035170634fe_-browser-action",
              "_c0e1baea-b4cb-4b62-97f0-278392ff8c37_-browser-action",
              "browserpass_maximbaz_com-browser-action",
              "_testpilot-containers-browser-action",
              "_20fc2e06-e3e4-4b2b-812b-ab431220cada_-browser-action",
              "tranquility_ushnisha_com-browser-action",
              "_0b457caa-602d-484a-8fe7-c1d894a011ba_-browser-action",
              "addon_darkreader_org-browser-action",
              "languagetool-webextension_languagetool_org-browser-action",
              "craig_wandrer_earth-browser-action",
              "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action"
            ],
            "dirtyAreaCache": [
              "nav-bar",
              "PersonalToolbar",
              "toolbar-menubar",
              "TabsToolbar",
              "widget-overflow-fixed-list",
              "unified-extensions-area"
            ],
            "currentVersion": 20,
            "newElementCount": 17
          }
        '';
      };

      # Search firefox extension
      #https://nur.nix-community.org/repos/rycee/
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        behind-the-overlay-revival # Block overlay mask
        browserpass # GPG passwordstore
        darkreader # Dark mode
        floccus # Sync bookmark
        onepassword-password-manager # Password manager
        simple-tab-groups # Tab group
        simple-translate # Translate
        # tomato-clock # Pomodoro timer
        ublock-origin # addblocker

        # Install manually addons
        # On addon website, get download link of the addon (install/uninstall button)
        # Fromt firefox (about:support) copy the addonId

        # LanguageTool, grammar and spell checker
        (buildFirefoxXpiAddon rec {
          pname = "fireshot";
          version = "8.3.0";
          addonId = "languagetool-webextension@languagetool.org";
          url =
            "https://addons.mozilla.org/firefox/downloads/file/4199245/languagetool-${version}.xpi";
          sha256 = "sha256-41dCTj353eS6EOufjzcZrEgwaBVwVX9NUdsVpGLNdmc=";
          meta = { };
        })

        # LanguageTool, grammar and spell checker
        (buildFirefoxXpiAddon rec {
          pname = "fireshot";
          version = "8.3.0";
          addonId = "languagetool-webextension@languagetool.org";
          url =
            "https://addons.mozilla.org/firefox/downloads/file/4199245/languagetool-${version}.xpi";
          sha256 = "sha256-41dCTj353eS6EOufjzcZrEgwaBVwVX9NUdsVpGLNdmc=";
          meta = { };
        })

        # Fireshot, screenshot
        (buildFirefoxXpiAddon rec {
          pname = "fireshot";
          version = "1.12.18";
          addonId = "{0b457cAA-602d-484a-8fe7-c1d894a011ba}";
          url =
            "https://addons.mozilla.org/firefox/downloads/file/4120150/fireshot-${version}.xpi";
          sha256 = "sha256-YAhLt3FW019rASp0wleegXdNXfoCHyzXd6JcrBjafyM=";
          meta = { };
        })

        # imtranslatoe
        (buildFirefoxXpiAddon rec {
          pname = "imtranslator";
          version = "16.30";
          addonId = "{9AA46F4F-4DC7-4c06-97AF-5035170634FE}";
          url =
            "https://addons.mozilla.org/firefox/downloads/file/4028792/imtranslator-${version}.xpi";
          sha256 = "sha256-9ZC3FmYXUWgZ+4VADX66cApOyJKmkgHWAi0zzovcn8U=";
          meta = { };
        })

        # Clean bookmark (duplicate links & unavailable links )
        (buildFirefoxXpiAddon rec {
          pname = "clean-up";
          version = "0.1.0";
          addonId = "{a1087d5d-d793-445a-b988-088b1d86f2a6}";
          url =
            "https://addons.mozilla.org/firefox/downloads/file/3610512/bookmarks_clean_up-${version}.xpi";
          sha256 = "sha256-4FNojXUkm+8lFEBbQOfpdlZgt/SfB8AAGCOiGyWnsuo=";
          meta = { };
        })

        # Clean bookmark (duplicate links & unavailable links )
        (buildFirefoxXpiAddon rec {
          pname = "linkding-extension";
          version = "1.14.0";
          addonId = "{61a05c39-ad45-4086-946f-32adb0a40a9d}";
          url =
            "https://addons.mozilla.org/firefox/downloads/file/4449452/linkding_extension-${version}.xpi";
          sha256 = "sha256-uORUU9Nmplslvk9Q59szaS9xk1SSV2hfT8K86zenB5w=";
          meta = { };
        })
      ];
    };
  };

  # home.persistence = {
  #   "/persist/user/${config.home.username}".directories = [ ".mozilla/firefox" ];
  # };
}
