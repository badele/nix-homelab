{
  pkgs,
  ...
}:
{
  services.printing = {
    enable = true;
    cups-pdf.enable = true;
    drivers = with pkgs; [
      hplipWithPlugin
    ];
  };

  programs.system-config-printer.enable = true;

  environment.systemPackages = with pkgs; [
    ghostscript # Pdf manipulation
  ];
}
