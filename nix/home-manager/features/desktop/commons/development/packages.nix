{ config
, pkgs
, ...
}: {

  home.packages = with pkgs; [
    deno # javascript engine
    # just # justfile (Makefile like)
    meld # Visual diff and merge tool
    vagrant # Virtual machine manager
    qemu # Virtual machine manager
    lazygit # git terminal UI
    lazydocker # docker terminal UI
  ];
}
