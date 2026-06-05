{
  pkgs,
  ...
}:
{

  environment.systemPackages = with pkgs; [
    libreoffice # Office suite
    inkscape # PDF manipulation
  ];
}
