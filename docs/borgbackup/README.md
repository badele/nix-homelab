# Borgbackup

<!--toc:start-->

- [Borgbackup](#borgbackup)
  - [Intro](#intro)
    - [Lexique](#lexique)
  - [Main Storage Box Account Setup](#main-storage-box-account-setup)
    - [Order a Storage Box](#order-a-storage-box)
    - [Configure SSH Access for the Main Account](#configure-ssh-access-for-the-main-account)
    - [Test Main Account SSH Access](#test-main-account-ssh-access)
  - [Passphrase generation](#passphrase-generation)
  - [Restoration](#restoration)
    - [Backup](#backup)
    - [Netbox](#netbox)

<!--toc:end-->

## Intro

Setup for using Borgbackup with Hetzner Storage Box. I use Hetzner's Storage Box
solution (Robot) for my backups. [Borgbackup](https://www.borgbackup.org/) is a
deduplicating backup program.

### Lexique

| Name          | Description                                                 |
| ------------- | ----------------------------------------------------------- |
| `ACCOUNTNAME` | a storage box account username name                         |
| `HOSTNAME`    | the client host name                                        |
| `PASSPHRASE`  | the borgbackup passphrase                                   |
| `REPOSITORY`  | the root borgbackup repository (`ssh://user@host:port`)     |
| `SERVICENAME` | the borgbackup path (can be an service or application name) |
| `ARCHIVEID`   | the borgbackup archive id for `SERVICENAME`                 |

## Main Storage Box Account Setup

### Order a Storage Box

Go to https://robot.hetzner.com/ and order a new storage box. An account ID and
a URL will be created in the following format:
`<ACCOUNTNAME>.your-storagebox.de`.

### Configure SSH Access for the Main Account

To simplify backup management following service movements that can switch from
one host to another, we will use the host's public key to connect without a
password to the Borgbackup SSH repository.

First, define your account name:

```bash
export ACCOUNTNAME="<YOUR_HETZNER_ACCOUNT_NAME>"
export HOSTNAME="<HOSTNAMECLIENT>"
```

Add your public key to the `.ssh/authorized_keys` file on your Storage Box.
You'll need your main account password for this step (retrieved via `pass` in
this example):

```bash
pass show home/bruno/hetzner.com/storagebox/${ACCOUNTNAME}
cat configuration/hosts/${HOSTNAME}/ssh_host_ed25519_key.pub | ssh -p23 ${ACCOUNTNAME}@${ACCOUNTNAME}.your-storagebox.de install-ssh-key
```

### Test Main Account SSH Access

From the client host, test that the SSH connection is working correctly without
a password:

```bash
pass nix-homelab/hosts/badxps/ssh_host_ed25519_key > /tmp/ssh && chmod 600 /tmp/ssh && ssh -i /tmp/ssh -p23 ${ACCOUNTNAME}@${ACCOUNTNAME}.your-storagebox.de ls -alh && rm -f /tmp/ssh
```

## Passphrase generation

Generate the borgbackup passphrase with

```bash
pwgen -s 32 1
```

and store to `configuration/hosts/secrets.yml` in `borgbackup/passphrase`
section

## Restoration

### Backup

```bash
sudo my-borg ${SERVICENAME} list ${BORG_REPO_BASE}/./netbox
( cd / && sudo my-borg ${SERVICENAME} extract ${BORG_REPO_BASE}/./netbox::badxps-netbox-2025-06-11T00:00:04)
```

### Netbox

```bash
sudo -u postgres dropdb netbox sudo -u postgres createdb netbox
nix shell nixpkgs#postgresql --command sudo -u postgres pg_restore -Fd -d netbox /data/borgbackup/postgresql/netbox
```
