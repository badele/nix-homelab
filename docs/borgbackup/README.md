# Borgbackup

<!--toc:start-->

- [Borgbackup](#borgbackup)
  - [Intro](#intro)
  - [Main Storage Box Account Setup](#main-storage-box-account-setup)
    - [Order a Storage Box](#order-a-storage-box)
    - [Configure SSH Access for the Main Account](#configure-ssh-access-for-the-main-account)
    - [Test Main Account SSH Access](#test-main-account-ssh-access)
  - [Passphrase generation](#passphrase-generation)
  - [Backup and Restoration](#backup-and-restoration)

<!--toc:end-->

## Intro

Setup for using Borgbackup with Hetzner Storage Box. I use Hetzner's Storage Box
solution (Robot) for my backups. [Borgbackup](https://www.borgbackup.org/) is a
deduplicating backup program.

## Main Storage Box Account Setup

### Order a Storage Box

Go to https://robot.hetzner.com/ and order a new storage box. An account ID and
a URL will be created in the following format: `<USERNAME>.your-storagebox.de`.

### Configure SSH Access for the Main Account

To simplify backup management, I use one account in the homelab infrastructure.
This allows services to move from one host to another without changing the host
private key.

The public/private SSH key and the borg backup passphrase are created and shared
across other hosts:

```bash
clan machines update houston

clan vars get houston borgbackup/borgbackup/borgbackup.ssh.pub | ssh -p23 u444061.your-storagebox.de install-ssh-key
```

### Test Main Account SSH Access

From the client host, test that the SSH connection is working correctly without
a password:

```bash
clan vars get houston borgbackup/borgbackup/borgbackup.ssh > /tmp/ssh && chmod 600 /tmp/ssh && ssh -i /tmp/ssh -p23 u444061@u444061.your-storagebox.de ls -alh && rm -f /tmp/ssh
```

## Backup maintenance

### List all scheduled backups

On server host

```bash
systemctl list-timers | grep -E 'NEXT|borg'
```

### Manual backup

```bash
clan backups create houston
```

### List backup

```bash
borgbackup-list
```

```bash
storagebox::u444061@u444061.your-storagebox.de:/./borgbackup::houston-storagebox-2025-07-24T01:00:00
storagebox::u444061@u444061.your-storagebox.de:/./borgbackup::houston-storagebox-2025-07-24T06:02:35
storagebox::u444061@u444061.your-storagebox.de:/./borgbackup::houston-storagebox-2025-07-25T01:00:02
```
