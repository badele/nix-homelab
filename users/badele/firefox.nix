{ pkgs, lib, inputs, ... }:
{
  programs.firefox = {
    enable = true;
    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      ublock-origin
      netflix-1080p
      browserpass # GPG passwordstore
      simple-tab-groups # Tab gropu
      vimium # Vim shorcut

      floccus # Sync bookmark
      behind-the-overlay-revival # Block overlay mask

      # imtranslator
      (buildFirefoxXpiAddon {
        pname = "imtranslator";
        version = "16.30";
        addonId = "{9AA46F4F-4DC7-4c06-97AF-5035170634FE}";
        url = "https://addons.mozilla.org/firefox/downloads/file/4028792/imtranslator-16.30.xpi";
        sha256 = "sha256-9ZC3FmYXUWgZ+4VADX66cApOyJKmkgHWAi0zzovcn8U=";
        meta = { };
      })

      # Clean bookmark (duplicate links & unavailable links & )
      (buildFirefoxXpiAddon {
        pname = "clean-up";
        version = "16.30";
        addonId = "{9AA46F4F-4DC7-4c06-97AF-5035170634FE}";
        url = "https://addons.mozilla.org/firefox/downloads/file/4028792/imtranslator-16.30.xpi";
        sha256 = "sha256-9ZC3FmYXUWgZ+4VADX66cApOyJKmkgHWAi0zzovcn8U=";
        meta = { };
      })

    ];
    profiles.badele = {
      bookmarks = { };
      settings = {
        "browser.startup.homepage" = "https://start.duckduckgo.com";
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
             "placements":{
                "widget-overflow-fixed-list":[
         
                ],
                "nav-bar":[
                   "back-button",
                   "forward-button",
                   "stop-reload-button",
                   "home-button",
                   "urlbar-container",
                   "library-button",
                   "downloads-button",
                   "ublock0_raymondhill_net-browser-action",
                   "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action",
                   "floccus_handmadeideas_org-browser-action",
                   "simple-tab-groups_drive4ik-browser-action",
                   "simple-translate_sienori-browser-action",
                   "_9aa46f4f-4dc7-4c06-97af-5035170634fe_-browser-action",
                   "_c0e1baea-b4cb-4b62-97f0-278392ff8c37_-browser-action",
                   "_a1087d5d-d793-445a-b988-088b1d86f2a6_-browser-action"
                ],
                "toolbar-menubar":[
                   "menubar-items"
                ],
                "TabsToolbar":[
                   "firefox-view-button",
                   "tabbrowser-tabs",
                   "new-tab-button",
                   "alltabs-button"
                ],
                "PersonalToolbar":[
                   "import-button",
                   "personal-bookmarks"
                ]
             },
             "seen":[
                "save-to-pocket-button",
                "developer-button",
                "ublock0_raymondhill_net-browser-action",
                "_a1087d5d-d793-445a-b988-088b1d86f2a6_-browser-action",
                "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action",
                "floccus_handmadeideas_org-browser-action",
                "simple-tab-groups_drive4ik-browser-action",
                "simple-translate_sienori-browser-action",
                "_9aa46f4f-4dc7-4c06-97af-5035170634fe_-browser-action",
                "_c0e1baea-b4cb-4b62-97f0-278392ff8c37_-browser-action"
             ],
             "dirtyAreaCache":[
                "nav-bar",
                "PersonalToolbar",
                "toolbar-menubar",
                "TabsToolbar",
                "widget-overflow-fixed-list"
             ],
             "currentVersion":18,
             "newElementCount":6
          }'';
      };
    };
  };

  # home.persistence = {
  #   "/persist/user/${config.home.username}".directories = [ ".mozilla/firefox" ];
  # };
}
