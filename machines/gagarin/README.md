# Gagarin Workstation

Gagarin is my main desktop workstation, named after Yuri Gagarin, the first human in space.

## Hardware

- **Type**: Desktop workstation
- **Location**: Home office
- **IP Address**: 192.168.254.147
- **Disk ID**: wwn-0x5000000000000314

## Configuration

### System

- **OS**: NixOS with full desktop environment
- **Disk Encryption**: LUKS encryption enabled
- **User**: badele (with wheel, audio, video, networkmanager, input groups)

### Desktop Environment

Gagarin runs a customized i3 tiling window manager setup with:

- **Window Manager**: [i3](../../nix/home-manager/features/desktop/xorg/wm/i3.nix)
- **Terminal**: Kitty / WezTerm
- **Shell**: Zsh with custom configuration
- **Editor**: [VIDE](https://github.com/badele/vide) (customized Neovim)

### Installed Applications

See the [Desktop Environment](../../README.md#-desktop-environment) section in the main README for a complete list of installed applications, including:

- **Development**: Neovim (VIDE), VS Code, Git, Docker
- **Productivity**: Firefox, LibreOffice, GIMP, Inkscape
- **Tools**: Meld, Navi, Borgbackup
- **Multimedia**: Media players and utilities

### Floating TUI Panels

Quick access panels for system management:
- **Bluetooth**: bluetuith
- **Disk Management**: bashmount
- **Audio Mixer**: pulsemixer
- **Network Manager**: nmtui

## Management

### Update System

```bash
# From local machine
clan machines update gagarin

# Or locally on gagarin
cd ~/ghq/github.com/badele/nix-homelab
just nixos-update
```

### User Configuration

User environment is managed through Home Manager with configurations in:
- Global: `../../modules/users/badele/`
- Machine-specific: `../../modules/users/badele/gagarin.nix`

## Initial Deployment

1. Boot from NixOS installer
2. Initialize the machine:
```bash
just nixos-init-host gagarin
```

3. Update disk configuration in `configuration.nix`
4. Deploy:
```bash
clan machines install gagarin
```
