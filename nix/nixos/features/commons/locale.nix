{ lib, ... }: {

  # Common locales
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

  # Xorg keyboad layout if Xorg is enabled
  services = {
    xserver = {
      xkb = {
        options = "caps:shiftlock";
        layout = "fr";
      };

    };

    # Touchpad
    libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        middleEmulation = false;
        naturalScrolling = true;
      };
    };

  };

  # Console keyboard layout
  console.keyMap = "fr";
}
