{ pkgs, outputs, lib, config, ... }:
let
  roleName = "virtualization";
  roleEnabled = lib.elem roleName config.homelab.currentHost.roles;
in
lib.mkIf (roleEnabled)
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  programs.virt-manager.enable = true;
}
