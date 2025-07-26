# Homelab administration

## Create clan USB installer

> [!NOTE]
> Skip this step if your have already installed one machine

Récupérer le chemin du device USB via la commande

```bash
lsblk
```

```bash
#clan flash list keymaps
#clan flash list languages

export USBDISK="/dev/sda"

ssh-add -L | head -n 1 > /tmp/ssh_key.pub
clan flash write --flake git+https://git.clan.lol/clan/clan-core \
  --ssh-pubkey /tmp/ssh_key.pub \
  --keymap fr \
  --language fr_FR.UTF-8 \
  --disk main ${USBDISK} \
  flash-installer
```

## Initialisation de la clef

> [!NOTE]
> Skip this step if your have already installed one machine

Avant d'administrer un hote, il faut créer les clef privée/publique age.

Si vous n'avez pas de clef [age](https://github.com/FiloSottile/age), vous
pouvez créer la clef avec la commande

```bash
clan secrets key generate
```

### Ajout de votre clef publique

Vous pouvez ajouter votre clef publique dans votre trousseau utilisateur

```bash
clan secrets users add badele --age-key <your_public_key>
```

## Ajout d'une nouvelle machine

```bash
clan vars generate [MACHINE]
```

## Deploy new machine

Insérer la clef USB précédemment crée

### Get disk device ID

Se connecter sur l'IP affiché et récupérer l'ID du disque via la commande
suivante

```bash
lsblk --output NAME,ID-LINK,FSTYPE,SIZE,MOUNTPOINT
```

metre à jours le fichier `machines/<hostname>/configuration.nix` pour mettre à
jours les attributs suivants `targetHost` and `device`

### Get hardware report

```bash
clan machines update-hardware-config [MACHINE]
```

### Install

```bash
clan machines install [MACHINE] --target-host <IP>
```
