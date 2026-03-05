{ lib, ... }:
with lib;
with types;
{
  options.hostprofile = {
    nproc = mkOption {
      type = int;
      default = 1;
      description = "Number of logical CPUs";
    };

    coretemp = mkOption {
      type = str;
      default = "/sys/class/hwmon/hwmon0/temp1_input";
      description = "Default hwmon path for CPU temperature";
    };

    autologin = {
      user = mkOption {
        type = str;
        default = "";
        description = "Autologin user";
      };

      session = mkOption {
        type = str;
        default = "";
        description = "Autologin session";
      };
    };
  };
}
