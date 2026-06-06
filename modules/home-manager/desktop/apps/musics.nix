# Musics
{ lib, pkgs, ... }:
{

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "reaper"
      ];
  };

  home.packages = with pkgs; [
    ardour # Digital Audio Workstation (DAW) for recording, editing, mixing and mastering music

    lmms-full # Linux MultiMedia Studio

    zrythm # Digital Audio Workstation (DAW) for recording, editing, mixing and mastering music

    reaper # Digital Audio Workstation (DAW) for recording, editing, mixing and mastering music
    reaper-reapack-extension # Package manager for REAPER that allows you to easily install and manage scripts, extensions and themes
    reaper-sws-extension # Collection of actions, scripts and utilities to enhance the functionality of REAPER

    qpwgraph # A Qt5-based pipewire patchbay
    pwvucontrol # A Qt5-based PipeWire volume control and session manager
    easyeffects # A powerful audio effects processor for PipeWire and JACK, with a user-friendly interface

    alsa-utils # A collection of utilities for configuring and using the ALSA sound system

    qtractor # Digital Audio Workstation (DAW) for recording, editing, mixing and mastering music

    wineWow64Packages.yabridge # A Wine-based VST bridge for Linux
    winetricks # A helper script to download and install various redistributable runtime libraries needed to run some programs in Wine

    yabridge # A Wine-based VST bridge for Linux
    yabridgectl # Command-line tool for yabridge

  ];
}
