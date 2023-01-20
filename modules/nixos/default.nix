{
  default = { lib, ... }: {
    options = {
      myDomain = lib.mkOption {
        type = lib.types.str;
      };
    };
  };
  dashy = import ./dashy.nix;
}
