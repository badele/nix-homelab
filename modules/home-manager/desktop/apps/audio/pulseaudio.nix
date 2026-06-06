{
  config,
  pkgs,
  ...
}:
{

  home.packages = with pkgs; [
    pulseaudio # A sound system for POSIX OSes
    pavucontrol # A Qt5-based PulseAudio volume control and session manager
    pulsemixer # A terminal-based PulseAudio mixer
  ];
}
