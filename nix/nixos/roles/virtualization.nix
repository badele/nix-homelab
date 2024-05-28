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
      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
  };

  programs.virt-manager.enable = true;
}
