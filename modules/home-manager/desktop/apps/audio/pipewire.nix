# Musics
{ lib, pkgs, ... }:
{

  home.packages = with pkgs; [
    wireplumber # wpctl for controlling PipeWire nodes
    qpwgraph # A Qt5-based pipewire patchbay
    pwvucontrol # A Qt5-based PipeWire volume control and session manager
    easyeffects # A powerful audio effects processor for PipeWire and JACK, with a user-friendly interface

    alsa-utils # A collection of utilities for configuring and using the ALSA sound system
    pulsemixer # A terminal-based PulseAudio mixer
  ];
}
