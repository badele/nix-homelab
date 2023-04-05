##########################################################
# HOME-MANAGER (user)
##########################################################
{ config
, inputs
, outputs
, pkgs
, lib
, ...
}:
let
  feh = "${pkgs.feh}/bin/feh";
in
{
  imports = [
    inputs.nix-colors.homeManagerModule

    # User
    ./base.nix

    # Term
    ../../nix/home-manager/features/term/base.nix
    ../../nix/home-manager/features/term/security

    # Language
    ../../nix/home-manager/features/language/python.nix

    # Desktop
    ../../nix/home-manager/features/desktop/commons/base.nix
    ../../nix/home-manager/features/desktop/xorg/base.nix
    ../../nix/home-manager/features/desktop/xorg/wm/i3.nix

    # Multimedia
    ../../nix/home-manager/features/desktop/commons/spotify.nix

    # Development term
    ../../nix/home-manager/features/term/development/base.nix

    # Development desktop
    ../../nix/home-manager/features/desktop/commons/development/base.nix
    ../../nix/home-manager/features/desktop/commons/development/vscode.nix
  ] ++ (builtins.attrValues outputs.homeManagerModules);

  programs = {
    ####################################
    # Monitors configuration
    ####################################
    autorandr = {
      enable = true;

      profiles = {
        "home-up" = {
          fingerprint = {
            eDP1 = "00ffffffffffff004d109a1400000000041c0104a52213780ede50a3544c99260f505400000001010101010101010101010101010101ac3780a070383e403020350058c210000018000000000000000000000000000000000000000000fe00544b365237804c513135364d31000000000002410328001200000a010a2020002b";
            DP3 = "00ffffffffffff0009d107779c0200000b110103802f1e78eecf75a455499927135054bdef80454f614f01018180818f714f0101010121399030621a274068b03600b10f1100001cd50980a0205e631010605208782d1100001a000000fd00384c1e5411000a202020202020000000fc0042656e51204650323232570a0a01d002031b71230907078301000067030c002000802d43100403e2000f8c0ad08a20e02d10103e9600a05a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018";
          };
          config = {
            eDP1 = {
              enable = true;
              primary = true;
              crtc = 0;
              position = "1680x0";
              mode = "1920x1080";
              rate = "60.00";
            };
            DP3 = {
              enable = true;
              crtc = 1;
              position = "0x0";
              mode = "1680x1050";
              rate = "60.00";
            };
          };
          hooks.postswitch = ''
            ${pkgs.i3}/bin/i3-msg restart
            ${feh} --bg-scale '${config.wallpaper}'
          '';
        };
      };
    };
  };

  # inv home.deploy ; neofetch ; ll
  colorscheme = inputs.nix-colors.colorSchemes.darktooth;
  wallpaper = pkgs.wallpapers.forest-deer-landscape;

  # OK colorscheme = inputs.nix-colors.colorSchemes.gruvbox-dark-soft;
  # OK colorscheme = inputs.nix-colors.colorSchemes.gruvbox-dark-medium;
  # OK colorscheme = inputs.nix-colors.colorSchemes.solarized-dark;

  # OK colorscheme = inputs.nix-colors.colorSchemes.shadesmear-dark;
  # OK colorscheme = inputs.nix-colors.colorSchemes.gruvbox-material-dark-hard;
  # OK colorscheme = inputs.nix-colors.colorSchemes.gruvbox-dark-hard;
  # OKcolorscheme = inputs.nix-colors.colorSchemes.tokyo-city-dark;
  # OK colorscheme = inputs.nix-colors.colorSchemes.google-dark;
  # OK colorscheme = inputs.nix-colors.colorSchemes.summerfruit-dark;
  # OK colorscheme = inputs.nix-colors.colorSchemes.unikitty-dark;

  # OK colorscheme = inputs.nix-colors.colorSchemes.default-dark;
  # OK colorscheme = inputs.nix-colors.colorSchemes.tokyo-city-terminal-dark
  # OK colorscheme = inputs.nix-colors.colorSchemes.horizon-dark;
  # OK colorscheme = inputs.nix-colors.colorSchemes.grayscale-dark;
  # OK colorscheme = inputs.nix-colors.colorSchemes.harmonic16-dark;
  # OK colorscheme = inputs.nix-colors.colorSchemes.equilibrium-gray-dark;
  # OK colorscheme = inputs.nix-colors.colorSchemes.humanoid-dark;
  # OK colorscheme = inputs.nix-colors.colorSchemes.brushtrees-dark;
  # OK colorscheme = inputs.nix-colors.colorSchemes.classic-dark;
  # OK colorscheme = inputs.nix-colors.colorSchemes.tokyo-night-dark;

  # NO colorscheme = inputs.nix-colors.colorSchemes.primer-dark-dimmed;
  # NO colorscheme = inputs.nix-colors.colorSchemes.tokyodark-terminal;
  # NO colorscheme = inputs.nix-colors.colorSchemes.onedark;
  # NO colorscheme = inputs.nix-colors.colorSchemes.darkviolet;
  # NO colorscheme = inputs.nix-colors.colorSchemes.outrun-dark;
  # NO colorscheme = inputs.nix-colors.colorSchemes.silk-dark;
  # NO colorscheme = inputs.nix-colors.colorSchemes.darkmoss;
  # NO colorscheme = inputs.nix-colors.colorSchemes.edge-dark;
  # NO colorscheme = inputs.nix-colors.colorSchemes.tokyo-night-terminal-dark;
  # NO colorscheme = inputs.nix-colors.colorSchemes.tokyodark; 

  # OK/NO colorscheme = inputs.nix-colors.colorSchemes.gruvbox-material-dark-medium;
  # OK/NO colorscheme = inputs.nix-colors.colorSchemes.black-metal-dark-funeral
  # OK/NO colorscheme = inputs.nix-colors.colorSchemes.horizon-terminal-dark;
  # OK/NO colorscheme = inputs.nix-colors.colorSchemes.gruvbox-dark-pale;


  # NO colorscheme = inputs.nix-colors.colorSchemes.synth-midnight-dark;

}
