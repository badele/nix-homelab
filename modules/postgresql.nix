{ ... }:
{
  services.postgresqlBackup = {
    enable = true;

    startAt = "*-*-* 02:10:00";
  };
}
