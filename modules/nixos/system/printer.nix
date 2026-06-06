{
  pkgs,
  ...
}:
{
  # Tips
  # lpinfo -v (detect printers)
  # hp-probe -busbus (detect HP printers)
  # lpstat -t (show printer status)
  # cups web interface: http://localhost:631

  programs.system-config-printer.enable = true;

  hardware.printers = {
    ensurePrinters = [
      {
        name = "HP-LaserJet-P1102";
        location = "Maison";
        deviceUri = "usb://HP/LaserJet%20Professional%20P1102";
        model = "drv:///hp/hpcups.drv/hp-laserjet_professional_p1102.ppd";
      }
    ];

    ensureDefaultPrinter = "HP-LaserJet-P1102";
  };

  services.printing = {
    enable = true;
    cups-pdf.enable = true;
    drivers = with pkgs; [
      hplipWithPlugin
    ];
  };

  environment.systemPackages = with pkgs; [
    ghostscript # Pdf manipulation
  ];
}
