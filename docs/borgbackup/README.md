# Borgbackup

Setup for using Borgbackup with Hetzner Storage Box. I use Hetzner's Storage Box
solution (Robot) for my backups. [Borgbackup](https://www.borgbackup.org/) is a
deduplicating backup program.

## 1. Main Storage Box Account Setup

### 1.1 Order a Storage Box

Go to https://robot.hetzner.com/ and order a new storage box. An account ID and
a URL will be created in the following format:
`<ACCOUNTNAME>.your-storagebox.de`.

### 1.2 Configure SSH Access for the Main Account

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

### 1.3 Test Main Account SSH Access

From the client host, test that the SSH connection is working correctly without
a password:

```bash
pass nix-homelab/hosts/badxps/ssh_host_ed25519_key > /tmp/ssh && chmod 600 /tmp/ssh && ssh -i /tmp/ssh -p23 ${ACCOUNTNAME}@${ACCOUNTNAME}.your-storagebox.de ls -alh && rm -f /tmp/ssh
```

## 2. Passphrase generation

Generate the borgbackup passphrase with

```bash
pwgen -s 32 1
```

and store to `configuration/hosts/secrets.yml`
