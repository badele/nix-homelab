{ pkgs,
  ... }:
{
  services.printing = {
    enable = true;
    drivers = with pkgs; [ hplipWithPlugin ];
  };

  programs.system-config-printer.enable = true;
}
