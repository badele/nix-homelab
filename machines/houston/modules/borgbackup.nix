{
  config,
  self,
  ...
}:
{
  clan.core.state.system.folders = [
    "/data"
    "/var"
  ];

  services.borgbackup.jobs.${config.networking.hostName} = {
    exclude = [
      "/var/cache"
      "/var/db"
      "/var/empty"
      "/var/lib/acme"
      "/var/lib/docker/"
      "/var/lib/homepage-dashboard"
      "/var/lib/postgresql" # already included in database backup
      "/var/lock"
      "/var/log"
      "/var/run"
      "/var/tmp"
    ];
  };
}
