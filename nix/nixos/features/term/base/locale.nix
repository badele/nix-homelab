{ lib, ... }: {
  console.keyMap = "fr";

  i18n = {
    defaultLocale = lib.mkDefault "fr_FR.UTF-8";
    extraLocaleSettings = {
      LC_TIME = lib.mkDefault "en_US.UTF-8";
    };
    supportedLocales = lib.mkDefault [
      "fr_FR.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };
  time.timeZone = lib.mkDefault "Europe/Paris";
}
