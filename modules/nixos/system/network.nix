{
  lib,
  ...
}:
{
  # resolvectl
  # resolvectl query google.com
  services.resolved.settings = {
    Resolve = {
      LLMNR = "no";
    };
  };
}
