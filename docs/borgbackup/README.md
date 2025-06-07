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

To connect automatically without a password, create an SSH key for your main
account.

First, define your account name:

```bash
export ACCOUNTNAME="<YOUR_HETZNER_ACCOUNT_NAME>"
```

Then, create the SSH key (using `just`):

```bash
just create-ssh-key externals hetzner_storagebox_${ACCOUNTNAME}
```

Add your public key to the `.ssh/authorized_keys` file on your Storage Box.
You'll need your main account password for this step (retrieved via `pass` in
this example):

```bash
pass show home/bruno/hetzner.com/storagebox/${ACCOUNTNAME}
cat configuration/externals/ssh/ssh_account_hetzner_storagebox_${ACCOUNTNAME}_ed25519_key.pub | ssh -p23 ${ACCOUNTNAME}@${ACCOUNTNAME}.your-storagebox.de install-ssh-key
```

### 1.3 Test Main Account SSH Access

Test that the SSH connection is working correctly:

```bash
pass nix-homelab/externals/ssh/ssh_account_hetzner_storagebox_${ACCOUNTNAME}_ed25519_key > /tmp/ssh && chmod 600 /tmp/ssh && ssh -i /tmp/ssh -p23 ${ACCOUNTNAME}@${ACCOUNTNAME}.your-storagebox.de ls -alh && rm -f /tmp/ssh
```

## 2. Sub-Account Setup for Services

It's recommended to create sub-accounts for specific services (e.g., Netbox
backups) to manage permissions more granularly.

### 2.1 Create a Sub-Account in Hetzner Interface

From the Hetzner Storage Box interface, create a sub-account. Ensure you check
`Allow SSH` and `External reachability`.

### 2.2 Define Sub-Account and Service Variables

Define the necessary variables for your sub-account and service:

```bash
export ACCOUNTNAME="<YOUR_HETZNER_ACCOUNT_NAME>"
export SUBACCOUNT="sub1" # Or any descriptive name for your sub-account
export SUBACCOUNTNAME="${ACCOUNTNAME}-${SUBACCOUNT}"
export SERVICENAME="netbox" # Or any descriptive name for the service (e.g., 'borgbackup_netbox')
```

### 2.3 Create a Directory for the Service (via Main Account)

Create a dedicated directory on your Storage Box for this sub-account's service.
This step is performed using your _main account_ SSH access.

```bash
pass nix-homelab/externals/ssh/ssh_account_hetzner_storagebox_${ACCOUNTNAME}_ed25519_key > /tmp/ssh && chmod 600 /tmp/ssh && ssh -i /tmp/ssh -p23 ${ACCOUNTNAME}@${ACCOUNTNAME}.your-storagebox.de mkdir -p ${SERVICENAME} && rm -f /tmp/ssh
```

### 2.4 Configure SSH Access for the Sub-Account

Create an SSH key specifically for this sub-account/service:

```bash
just create-ssh-key services borgbackup_${SERVICENAME}
```

Add this new public key to the `.ssh/authorized_keys` file of the _sub-account_
on your Storage Box. You'll need the sub-account's password for this step
(retrieved via `pass` in this example):

```bash
pass show home/bruno/hetzner.com/storagebox/subaccount/${SERVICENAME}
cat configuration/services/ssh/ssh_account_borgbackup_${SERVICENAME}_ed25519_key.pub | ssh -p23 ${SUBACCOUNTNAME}@${ACCOUNTNAME}.your-storagebox.de install-ssh-key
```

### 2.5 Test Sub-Account SSH Access

Test that the SSH connection for the sub-account is working correctly:

```bash
pass nix-homelab/services/ssh/ssh_account_borgbackup_netbox_ed25519_key > /tmp/ssh && chmod 600 /tmp/ssh && ssh -i /tmp/ssh -p23 ${SUBACCOUNTNAME}@${ACCOUNTNAME}.your-storagebox.de ls -alh && rm -f /tmp/ssh
```
